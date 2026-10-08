(** Entry point for Camltac vernacular commands. *)

(** {1 Syntactic interpretation} *)

(** {2 Validation} *)

let check_module_not_loaded ~loc name =
  if Module_manager.is_loaded name then
    CErrors.user_err ~loc (Pp.(str "Module " ++ str name ++ str " already exists."))

(** {2 Compilation} *)

let compile_file ~loc mode file =
  let context = Compiler.{
    alias_module = Module_manager.alias_module ();
    dependencies = Module_manager.dependencies ();
    modules_dirs = Module_manager.modules_dirs ()
  }
  in
  match Compiler.compile ~context mode file with
  | Ok out -> out
  | Error code ->
     let file = Build_file.locate file in
     CErrors.user_err ~loc (Pp.(str "Compilation of " ++ str file ++ str " failed with error " ++ int code ++ str "."))

let compile_scaffold ~loc mode scaffold =
  let kind =
    match mode with
    | Snippet.Module { name = Some (name, loc); _ } ->
       check_module_not_loaded ~loc name;
       Build_file.Module
    | _ -> Build_file.Snippet
  in
  let build_file = Build_file.write ~kind scaffold in
  match mode with
  | Check_expression | Check_module ->
     compile_file ~loc Ocamlfind.Infer_interface build_file
  | Module { name; _ } ->
     (* Declare the module at synterp time. *)
     let name = Option.map fst name in
     let out = compile_file ~loc Ocamlfind.(Shared_library { linkall = true }) build_file in
     Module_manager.declare_module name out;
     out
  | _ -> compile_file ~loc Ocamlfind.(Shared_library { linkall = true }) build_file

let compile_snippet mode snippet =
  let loc = Snippet.loc snippet in
  let scaffold = Snippet.scaffold mode snippet in
  compile_scaffold ~loc mode scaffold

(** {1 Interpretation} *)

let read_interface file =
  Build_file.locate file
  |> File.read
  |> String.trim

let simplify_interface intf =
  (* Simplify interface for single-values. *)
  let prefix = "val ( - )" in
  if String.starts_with ~prefix intf then
    let l = String.length prefix in
    "-" ^ String.sub intf l (String.length intf - l)
  else
    intf

let get_type Compiler.{ compiled_file = mli_file; _ } =
  let intf = read_interface mli_file in
  let regexp = Str.regexp {|val ( - ) : \([^ ]+\) tactic|} in
  let _ = Str.search_forward regexp intf 0 in
  Str.matched_group 1 intf

[%%if rocq >= (9, 2)]
let poly_default = PolyFlags.default
[%%else]
let poly_default = false
[%%endif]

let interpret ?proof (mode: Snippet.execution_mode) (Compiler.{ compiled_file; dependencies } as compilation_output) =
  match mode with
  | Check_expression | Check_module ->
     (* Read the interface from the [.mli] file. *)
     let mli_file = compiled_file in
     let intf = read_interface mli_file in
     let intf = simplify_interface intf in
     Feedback.msg_info (Pp.str intf)
  | Eval typ ->
     Loader.load_file ~dependencies `Private compiled_file;
     let tactic: string Proofview.tactic = Runtime.Output.get_tactic () in
     let env = Global.env () in
     let proof =
       match proof with
       | None ->
          let sigma = Evd.from_env env in
          let name = Names.Id.of_string "camltac" in
          Proof.start ~name ~poly:poly_default sigma []
       | Some proof ->
          Declare.Proof.get proof
     in
     let (_, _, result) = Proof.run_tactic env tactic proof in
     Feedback.msg_info Pp.(str "- : " ++ str typ ++ spc () ++ str "=" ++ spc () ++ str result)
  | Module { locality; name; _ } ->
     (* [Module_manager] handles module loading. *)
     let name = Option.map fst name in
     Module_manager.load_module ~locality name compilation_output
  | _ ->
     Loader.load_file ~dependencies `Private compiled_file
