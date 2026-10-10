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
  | Module info ->
     { kind = (match info.name with
              | Some _ -> Module
              | None -> Snippet);
       mode = Shared_library { linkall = true };
       recorded = Record info
     }
  | Eval | Tactic_in_term | Tactic_in_Ltac | Tactic_in_Ltac2 ->
     { kind = Snippet;
       mode = Shared_library { linkall = true };
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

let rec scaffold_mode snippet = function
  | Check_expression ->
     Infer_type
  | Eval ->
     (* Infer the type of the tactic to scaffold correctly. *)
     let out = synterp Check_expression snippet in
     begin match Interface.tactic_type (Interface.read out.Compiler.file) with
     | Some typ -> Show_tactic { typ }
     | None -> CErrors.user_err ~loc:(Snippet.loc snippet) (Pp.str "Argument to Eval is not a tactic.")
     end
  | Tactic_in_term | Tactic_in_Ltac | Tactic_in_Ltac2 ->
     Tactic
  | Module _ | Check_module ->
     Plain

and synterp ?(directives = Build_directives.empty) cmd snippet =
  let build = build_of_cmd cmd in
  let scaffold_mode = scaffold_mode snippet cmd in
  Scaffold.make scaffold_mode snippet
  |> Build_file.write ~kind:build.kind
  |> Compiler.compile ~args:(Compile_context.current ()) ~directives build.mode
  |> Result.fold ~ok:(record_out build.recorded) ~error:(fun err -> CErrors.user_err ~loc:(Snippet.loc snippet) (Compiler.pp_error err))

(** {1 Interpretation} *)

(** {2 [Check]} *)

let check out =
  let open Compiler in
  Interface.read out.file
  |> Interface.pp
  |> Feedback.msg_info

(** {2 [Module]} *)

let load_module { name; locality } out =
  match name with
  | Some (name, loc) ->
     if Module_manager.is_loaded name then
       CErrors.user_err ~loc (Pp.(str "Module " ++ str name ++ str " already exists."));
     Module_manager.load_module ~locality (Some name) out
  | None ->
     Module_manager.load_module ~locality None out

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
