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

(** {1 Syntactic interpretation} *)

(** {2 Build plan} *)

(** Whether a snippet's compilation should be recorded in [Libobject]. *)
type recorded =
  | Do_not_record
  (** Do not persist the snippet in the [.vo] file. *)

  | Record of string option
  (** Record the snippet with the given name. *)

type build =
  { kind     : Build_file.kind; (** Kind of build file generated. *)
    mode     : Ocamlfind.mode;  (** Mode of the OCaml compiler to use. *)
    recorded : recorded;        (** Whether the snippet compilation is recorded in [Libobject]. *)
  }

let build_of_cmd = function
  | Check_expression | Check_module ->
     { kind = Snippet;
       mode = Infer_interface;
       recorded = Do_not_record
     }
  | Module { name = Some (name, _); _ } ->
     { kind = Module;
       mode = Shared_library { linkall = true };
       recorded = Record (Some name)
     }
  | Module { name = None; _ } ->
     { kind = Snippet;
       mode = Shared_library { linkall = true };
       recorded = Record None
     }
  | Eval | Tactic_in_term | Tactic_in_Ltac | Tactic_in_Ltac2 ->
     { kind = Snippet;
       mode = Shared_library { linkall = true };
       recorded = Do_not_record
     }

(** {2 Compilation} *)

let current_context () =
  Compiler.{
      alias_module = Module_manager.alias_module ();
      dependencies = Module_manager.dependencies ();
      modules_dirs = Module_manager.modules_dirs ()
  }

let report_error ~loc err =
  CErrors.user_err ~loc (Pp.fmt "Compilation failed with exit code %d." err)

let record_out recorded out =
  let () =
    match recorded with
    | Do_not_record -> ()
    | Record name -> Module_manager.declare_module name out
  in out

let rec scaffold_mode snippet = function
  | Check_expression ->
     Infer_type
  | Eval ->
     (* Infer the type of the tactic to scaffold correctly. *)
     let out = compile_snippet Check_expression snippet in
     begin match Interface.tactic_type (Interface.read out.Compiler.compiled_file) with
     | Some typ -> Show_tactic { typ }
     | None -> CErrors.user_err ~loc:(Snippet.loc snippet) (Pp.fmt "Argument to Eval is not a tactic.")
     end
  | Tactic_in_term | Tactic_in_Ltac | Tactic_in_Ltac2 ->
     Tactic
  | Module _ | Check_module ->
     Plain

and compile_snippet cmd snippet =
  let build = build_of_cmd cmd in
  let scaffold_mode = scaffold_mode snippet cmd in
  Scaffold.make scaffold_mode snippet
  |> Build_file.write ~kind:build.kind
  |> Compiler.compile ~context:(current_context ()) build.mode
  |> Result.fold ~ok:(record_out build.recorded) ~error:(report_error ~loc:(Snippet.loc snippet))

(** {1 Interpretation} *)

(** {2 [Check]} *)

let check out =
  let open Compiler in
  Interface.read out.compiled_file
  |> Interface.pp
  |> Feedback.msg_info

(** {2 [Module]} *)

let load_module { name; locality } out =
  match name with
  | Some (name, loc) ->
     if Module_manager.is_loaded name then
       CErrors.user_err ~loc (Pp.fmt "Module %s already exists." name);
     Module_manager.load_module ~locality (Some name) out
  | None ->
     Module_manager.load_module ~locality None out

(** {2 [Eval]} *)

let load Compiler.{ dependencies; compiled_file } =
  Loader.load_file ~dependencies `Private compiled_file

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

(** {2 Interpretation function} *)

let interpret ?proof cmd (out: Compiler.output) =
  match cmd with
  | Check_expression | Check_module -> check out
  | Eval -> eval ?proof out
  | Module m -> load_module m out
  | Tactic_in_term | Tactic_in_Ltac | Tactic_in_Ltac2 -> load out
