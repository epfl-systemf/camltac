(** Main driver. *)

open Names
open Scaffold

(** {1 Commands} *)

module Command = struct
  type t =
    | Module of module_info
    | Eval
    | Check_expression
    | Check_module
    | Tactic_in_term
    | Tactic_in_Ltac
    | Tactic_in_Ltac2

  and module_info =
    { name: string option;
      locality: Libobject.locality;
    }

  let compilation_mode = function
    | Module _ | Eval | Tactic_in_term | Tactic_in_Ltac | Tactic_in_Ltac2 ->
       Compiler.Shared_library { linkall = true }
    | Check_expression | Check_module ->
       Compiler.Infer_interface
end

open Command

(** {2 Synterp} *)

type synterp_result = Command.t * Compiler.Artifact.t

(** {3 Compilation arguments} *)

let default_args =
  let open Compilation_args in
  empty
  |> add_packages ["rocq-camltac.plugin.runtime"; "rocq-camltac.plugin.api"; "ppx_rocq.runtime"]
  |> add_open_modules ["Api"; "Prelude"]

let current_args ~state =
  let modules = Synterp.artifacts state in
  let open Compilation_args in
  default_args
  |> add_packages (List.concat_map Compiler.Artifact.dependencies modules)
  |> add_include_dirs (List.map Compiler.Artifact.dirname modules)

let pp_flag ~workspace ~file ~ppxs snippet =
  match Preprocessing.select_driver ~workspace ~file ~ppxs ~source:(Snippet.contents snippet) with
  | Ok driver -> Preprocessing.pp_flag driver
  | Error err ->
     CErrors.user_err ~loc:(Snippet.loc snippet)
       Pp.(str "Compilation of PPX driver failed with exit code " ++ int err)

let compilation_args ~workspace ~file ~directives ~state snippet =
  current_args ~state
  |> Directives.extend_args directives
  |> Compilation_args.add_pp (pp_flag ~workspace ~file ~ppxs:directives.Directives.ppx snippet)

(** {3 Compilation} *)

(** Records the compilation of a module in [Libobject]. *)
let record_out cmd out =
  let () =
    match cmd with
    | Module { name; locality } -> Synterp.declare ~locality ~name out
    | _ -> ()
  in out

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
     let _, out = synterp Check_expression snippet in
     begin match Interface.tactic_type (Interface.read (Compiler.Artifact.file out)) with
     | Some typ -> Value_tactic { typ }
     | None -> CErrors.user_err ~loc:(Snippet.loc snippet) (Pp.str "Argument to Eval is not a tactic.")
     end
  | Tactic_in_term | Tactic_in_Ltac | Tactic_in_Ltac2 ->
     Unit_tactic
  | Module { name; _ } ->
     Scaffold.Module { name }
  | Check_module ->
     Scaffold.Module { name = None }

and synterp ?(directives = Directives.empty) cmd snippet =
  let scaffold_mode = scaffold_mode snippet cmd in
  let workspace = Workspace.at (Current_library.cwd ()) in
  let file = Current_library.top_module_name () in
  let loaded_units = Loader.loaded_units () in
  let state = Synterp.current () in
  let aliases = CString.Map.bindings (Synterp.module_name_map state) in
  let args = compilation_args ~workspace ~file ~directives ~state snippet in
  Scaffold.make scaffold_mode ~aliases snippet
  |> create_build_file ~workspace ~file ~loaded_units ~args cmd
  |> compile ~args ~source:snippet (Command.compilation_mode cmd)
  |> record_out cmd
  |> fun out -> cmd, out

(** {2 Interpretation} *)

module Interp = struct

  (** {3 [Check]} *)

  let check out =
    Interface.read (Compiler.Artifact.file out)
    |> Interface.pp
    |> Feedback.msg_info

  (** {3 [Module]} *)

  let check_module_shadowing state = function
    | Some name ->
       if Interp.is_loaded name state then
         Feedback.msg_warning (Pp.(str "Module " ++ str name ++ str " shadows a previously-defined module."))
    | None -> ()

  let load_module ~name ~locality out =
    check_module_shadowing (Interp.current ()) name;
    Interp.load_module ~locality ~name out

  (** {3 [Eval]} *)

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

  let run ?proof (cmd, out) =
    match cmd with
    | Module { name; locality } -> load_module ~name ~locality out
    | Eval -> eval ?proof out
    | Check_expression | Check_module -> check out
    | Tactic_in_term | Tactic_in_Ltac | Tactic_in_Ltac2 -> load out
end

let interp = Interp.run
