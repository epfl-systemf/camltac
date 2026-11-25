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

type synterp_result = Compiler.Artifact.t

(** {2 Build plan} *)

(** Whether a snippet's compilation should be recorded in [Libobject]. *)
type recorded =
  | Do_not_record
  (** Do not persist the snippet in the [.vo] file. *)

  | Record of module_info
  (** Record the snippet with the given name. *)

type build =
  { mode     : Compiler.mode;     (** Mode of the OCaml compiler to use. *)
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
       Synterp.declare
         ~name:(Option.map fst module_info.name)
         ~locality:module_info.locality
         out
  in out

(** Default compilation arguments, which are always passed. *)
let default_args =
  let open Compilation_args in
  empty
  |> add_packages ["rocq-camltac.plugin.runtime"; "rocq-camltac.plugin.api"; "ppx_rocq.runtime"]
  |> add_open_modules ["Api"; "Prelude"]

(** Compilation arguments that depend on the modules declared in [state]. *)
let current_args ~state =
  let artifacts = Synterp.artifacts state in
  let open Compilation_args in
  default_args
  |> add_packages (List.concat_map Compiler.Artifact.dependencies artifacts)
  |> add_include_dirs (List.map Compiler.Artifact.dirname artifacts)

(** Compilation arguments for [snippet]: the current compilation context,
    extended with the build directives and the preprocessor. *)
let compilation_args ~workspace ~file ~directives ~state snippet =
  let ppxs = directives.Directives.ppx in
  let pp =
    match Preprocessing.select_driver ~workspace ~file ~ppxs ~source:(Snippet.contents snippet) with
    | Ok driver -> Preprocessing.pp_flag driver
    | Error err ->
       CErrors.user_err ~loc:(Snippet.loc snippet)
         Pp.(str "Compilation of PPX driver failed with exit code " ++ int err)
  in
  current_args ~state
  |> Directives.extend_args directives
  |> Compilation_args.add_pp pp

(** Compiles a build file, reporting diagnostics. *)
let compile ~args ~source mode build_file =
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
let create_build_file ~workspace ~file ~loaded_units ~args cmd contents =
  match cmd with
  | Check_module -> Build_file.generate ~workspace ~dir:".check" ~name:file contents
  | _ ->
     let source_file = Source_file.create ~workspace ~file contents in
     Editor_support.create_merlin_file ~workspace ~args source_file;
     Build_file.copy_source ~workspace ~loaded_units source_file

let rec scaffold_mode snippet = function
  | Check_expression -> Expression
  | Eval ->
     (* Infer the type of the tactic to scaffold correctly. *)
     let out = synterp Check_expression snippet in
     begin match Interface.tactic_type (Interface.read (Compiler.Artifact.file out)) with
     | Some typ -> Value_tactic { typ }
     | None -> CErrors.user_err ~loc:(Snippet.loc snippet) (Pp.str "Argument to Eval is not a tactic.")
     end
  | Tactic_in_term | Tactic_in_Ltac | Tactic_in_Ltac2 ->
     Unit_tactic
  | Module { name = Some (name, _); _ } ->
     Module { name = Some name }
  | Module { name = None; _ } | Check_module ->
     Module { name = None }

and synterp ?(directives = Directives.empty) cmd snippet =
  let build = build_of_cmd cmd in
  let scaffold_mode = scaffold_mode snippet cmd in
  let workspace = Workspace.at (Current_library.cwd ()) in
  let file = Current_library.top_module_name () in
  let loaded_units = Loader.loaded_units () in
  let state = Synterp.current () in
  let aliases = CString.Map.bindings (Synterp.module_name_map state) in
  let args = compilation_args ~workspace ~file ~directives ~state snippet in
  Scaffold.make scaffold_mode ~aliases snippet
  |> create_build_file ~workspace ~file ~loaded_units ~args cmd
  |> compile ~args ~source:snippet build.mode
  |> record_out build.recorded

(** {1 Interpretation} *)

(** {2 [Check]} *)

let check out =
  Interface.read (Compiler.Artifact.file out)
  |> Interface.pp
  |> Feedback.msg_info

(** {2 [Module]} *)

let check_module_shadowing state = function
  | Some name ->
     if Interp.is_loaded name state then
       Feedback.msg_warning (Pp.(str "Module " ++ str name ++ str " shadows a previously-defined module."))
  | None -> ()

let load_module { name; locality } out =
  let name = Option.map fst name in
  check_module_shadowing (Interp.current ()) name;
  Interp.load_module ~locality ~name out

(** {2 [Eval]} *)

let load out =
  Loader.load_file ~dependencies:(Compiler.Artifact.dependencies out) `Private (Compiler.Artifact.file out)

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

let interp ?proof cmd (out: Compiler.Artifact.t) =
  match cmd with
  | Check_expression | Check_module -> check out
  | Eval -> eval ?proof out
  | Module m -> load_module m out
  | Tactic_in_term | Tactic_in_Ltac | Tactic_in_Ltac2 -> load out
