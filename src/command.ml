(** Entry point for Camltac vernacular commands. *)

open Names
open Scaffold

(** {1 Commands} *)

type module_info =
  { name: (string * Loc.t) option;
    locality: Libobject.locality;
  }

type t =
  | Eval
  | Check_expression
  | Check_module
  | Module of module_info
  | Tactic_in_term
  | Tactic_in_Ltac
  | Tactic_in_Ltac2

(** {1 Synterp} *)

type synterp_result = Compiler.compiled

(** {2 Build plan} *)

(** Whether a snippet's compilation should be recorded in [Libobject]. *)
type recorded =
  | Do_not_record
  (** Do not persist the snippet in the [.vo] file. *)

  | Record of module_info
  (** Record the snippet with the given name. *)

type build =
  { mode     : Ocamlfind.mode;  (** Mode of the OCaml compiler to use. *)
    recorded : recorded;        (** Whether the snippet compilation is recorded in [Libobject]. *)
  }

let build_of_cmd = function
  | Check_expression | Check_module ->
     { mode = Infer_interface;
       recorded = Do_not_record
     }
  | Module info ->
     { mode = Shared_library { linkall = true };
       recorded = Record info
     }
  | Eval | Tactic_in_term | Tactic_in_Ltac | Tactic_in_Ltac2 ->
     { mode = Shared_library { linkall = true };
       recorded = Do_not_record
     }

(** {2 Compilation} *)

let record_out recorded out =
  let () =
    match recorded with
    | Do_not_record -> ()
    | Record module_info ->
       Compile_context.declare_module
         ~name:module_info.name
         ~locality:module_info.locality
         out
  in out

(** Compilation arguments for [snippet]: the current compilation context,
    extended with the build directives and the preprocessor. *)
let compilation_args ~workspace ~file ~directives snippet =
  let ppxs = directives.Build_directives.ppx in
  let pp =
    match Preprocessing.select_driver ~workspace ~file ~ppxs ~source:(Snippet.contents snippet) with
    | Ok driver -> Preprocessing.pp_flag driver
    | Error err ->
       CErrors.user_err ~loc:(Snippet.loc snippet)
         Pp.(str "Compilation of PPX driver failed with exit code " ++ int err)
  in
  let open Compilation_args in
  Compile_context.current ()
  |> add_packages directives.libraries
  |> add_packages (List.concat_map Ocaml_packages.ppx_runtime_deps ppxs)
  |> add_extras directives.compiler_options
  |> add_pp pp

(** Compiles a build file, reporting diagnostics. *)
let compile ~workspace ~file ~directives ~source mode build_file =
  let args = compilation_args ~workspace ~file ~directives source in
  let result, diagnostics = Compiler.compile ~args mode build_file in
  Error_reporter.report_all ~source diagnostics;
  match result with
  | Ok artifact -> artifact
  | Error code ->
     (* Compilation errors are reported by [Error_reporter], so this case
        covers other types of errors. *)
     CErrors.user_err ~loc:(Snippet.loc source)
       Pp.(str "Compilation failed with exit code " ++ int code ++ str ".")

(** Writes the scaffolded snippet to a source file, then copies it to the build
    directory. Module checks are not meant to be inspected, hence the source is
    only generated in the build directory. *)
let create_build_file ~workspace ~file ~loaded_units cmd contents =
  match cmd with
  | Check_module -> Build_file.generate ~workspace ~dir:".check" ~name:file contents
  | _ ->
     Source_file.create ~workspace ~file contents
     |> Build_file.copy_source ~workspace ~loaded_units

let rec scaffold_mode snippet = function
  | Check_expression -> Expression
  | Eval ->
     (* Infer the type of the tactic to scaffold correctly. *)
     let out = synterp Check_expression snippet in
     begin match Interface.tactic_type (Interface.read out.Compiler.file) with
     | Some typ -> Value_tactic { typ }
     | None -> CErrors.user_err ~loc:(Snippet.loc snippet) (Pp.str "Argument to Eval is not a tactic.")
     end
  | Tactic_in_term | Tactic_in_Ltac | Tactic_in_Ltac2 ->
     Unit_tactic
  | Module { name = Some (name, _); _ } ->
     Module { name = Some name }
  | Module { name = None; _ } | Check_module ->
     Module { name = None }

and synterp ?(directives = Build_directives.empty) cmd snippet =
  let build = build_of_cmd cmd in
  let scaffold_mode = scaffold_mode snippet cmd in
  let workspace = Workspace.at (Current_library.cwd ()) in
  let file = Current_library.top_module_name () in
  let loaded_units = Loader.loaded_units () in
  Scaffold.make scaffold_mode snippet
  |> create_build_file ~workspace ~file ~loaded_units cmd
  |> compile ~workspace ~file ~directives ~source:snippet build.mode
  |> record_out build.recorded

(** {1 Interpretation} *)

(** {2 [Check]} *)

let check out =
  Interface.read out.Compiler.file
  |> Interface.pp
  |> Feedback.msg_info

(** {2 [Module]} *)

let load_module { name; locality } out =
  match name with
  | Some (name, loc) ->
     if Loaded_modules.is_loaded name then
       CErrors.user_err ~loc (Pp.(str "Module " ++ str name ++ str " already exists."));
     Loaded_modules.load_module ~locality ~name:(Some name) out
  | None ->
     Loaded_modules.load_module ~locality ~name:None out

(** {2 [Eval]} *)

let load Compiler.{ packages; file } =
  Loader.load_file ~dependencies:packages `Private file

[%%if rocq >= (9, 2)]
let poly_default = PolyFlags.default
[%%else]
let poly_default = false
[%%endif]

let run_tactic ?proof tactic =
  let env = Global.env () in
  let proof =
    match proof with
    | None ->
       let sigma = Evd.from_env env in
       let name = Id.of_string "camltac" in
       Proof.start ~name ~poly:poly_default sigma []
    | Some proof ->
       Declare.Proof.get proof
  in
  let (_, _, result) = Proof.run_tactic env tactic proof in
  result

let eval ?proof out =
  load out;
  let tactic : Pp.t Proofview.tactic = Runtime.Output.get_tactic () in
  let result = run_tactic ?proof tactic in
  Feedback.msg_info result

(** {1 Interp} *)

let interp ?proof cmd (out: Compiler.compiled) =
  match cmd with
  | Check_expression | Check_module -> check out
  | Eval -> eval ?proof out
  | Module m -> load_module m out
  | Tactic_in_term | Tactic_in_Ltac | Tactic_in_Ltac2 -> load out
