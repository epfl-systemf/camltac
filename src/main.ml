(** Entry point for Camltac vernacular commands. *)

(** {1 Syntactic interpretation} *)

(** {2 Validation} *)

let check_module_name ~loc (name: string) =
  match String.get name 0 with
  | 'A'..'Z' -> ()
  | _ ->
    let suggestion = String.capitalize_ascii name in
    CErrors.user_err ~loc (Pp.fmt "Module names must be capitalized.\nHint: did you mean %S?" suggestion)

let check_file ~loc (file: string) =
  if not (Sys.file_exists file) then
    CErrors.user_err ~loc (Pp.fmt "File %S does not exist." file)

(** {2 Compilation} *)

let compile_file ~loc file =
  check_file ~loc file;
  let context = Compiler.{
    packing_module = Module_manager.packing_module ();
    loaded_dependencies = Module_manager.loaded_dependencies ()
  }
  in
  match Compiler.compile_with_directives ~context file with
  | Ok out -> out
  | Error code ->
     CErrors.user_err ~loc (Pp.fmt "Compilation of %s failed with error %d." file code)

let infer_interface ~loc file =
  check_file ~loc file;
  let context = Compiler.{
    packing_module = Module_manager.packing_module ();
    loaded_dependencies = Module_manager.loaded_dependencies ()
  }
  in
  match Compiler.infer_interface ~context file with
  | Ok out -> out
  | Error code ->
     CErrors.user_err ~loc (Pp.fmt "Compilation of %s failed with error %d." file code)

let compile_scaffold ~loc mode scaffold =
  let build_file =
    match mode with
    | Snippet.Module { name; loc = name_loc } ->
       check_module_name ~loc:name_loc name;
       if Module_manager.is_loaded name then
         CErrors.user_err ~loc (Pp.fmt "Module %S already exists." name)
       else
         Build_files.save_module scaffold
    | _ -> Build_files.save_snippet scaffold
  in
  match mode with
  | Check -> infer_interface ~loc build_file
  | _ -> compile_file ~loc build_file

let compile_snippet mode snippet =
  let loc = Snippet.loc snippet in
  let scaffold = Snippet.scaffold mode snippet in
  compile_scaffold ~loc mode scaffold

(** {1 Interpretation} *)

let read_interface file =
  let in_channel = In_channel.open_text file in
  let intf = In_channel.input_all in_channel in
  In_channel.close_noerr in_channel;
  String.trim intf

let simplify_interface intf =
  (* Simplify interface for single-values. *)
  let prefix = "val ( - )" in
  if String.starts_with ~prefix intf then
    let l = String.length prefix in
    "-" ^ String.sub intf l (String.length intf - l)
  else
    intf

let get_type Compiler.{ compiled_file = mli_file } =
  let intf = read_interface mli_file in
  let regexp = Str.regexp {|val ( - ) : \([^ ]+\) tactic|} in
  let _ = Str.search_forward regexp intf 0 in
  Str.matched_group 1 intf

let interpret ?proof (mode: Snippet.execution_mode) (Compiler.{ compiled_file; dependencies } as compilation_output) =
  match mode with
  | Check ->
     (* Read the interface from the [.mli] file. *)
     let mli_file = compiled_file in
     let intf = read_interface mli_file in
     let intf = simplify_interface intf in
     Feedback.msg_info (Pp.str intf)
  | Eval typ ->
     Loader.load_file ~public:false ~dependencies compiled_file;
     let tactic: string Proofview.tactic = Runtime.Output.get_tactic () in
     let env = Global.env () in
     let proof =
       match proof with
       | None ->
          let sigma = Evd.from_env env in
          let name = Names.Id.of_string "camltac" in
          Proof.start ~name ~poly:PolyFlags.default sigma []
       | Some proof ->
          Declare.Proof.get proof
     in
     let (_, _, result) = Proof.run_tactic env tactic proof in
     Feedback.msg_info Pp.(str "- : " ++ str typ ++ spc () ++ str "=" ++ spc () ++ str result)
  | Module { locality; name } ->
     (* [Module_manager] handles module loading. *)
     Module_manager.declare_module ~locality name compilation_output
  | _ ->
     Loader.load_file ~public:false ~dependencies compiled_file
