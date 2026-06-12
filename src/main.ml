(** Entry point for Camltac vernacular commands. *)

(** {1 Syntactic interpretation} *)

(** {2 Validation} *)

let check_module_name ~loc (name: string) =
  if not (Char.Ascii.is_upper (String.get name 0)) then
    let suggestion = String.capitalize_ascii name in
    CErrors.user_err ~loc (Pp.fmt "Module names must be capitalized.\nHint: did you mean %S?" suggestion)

let check_file ~loc (file: string) =
  if not (Sys.file_exists file) then
    CErrors.user_err ~loc (Pp.fmt "File %S does not exist." file)

(** {2 Compilation} *)

let compile_file ~loc file =
  check_file ~loc file;
  match Compiler.compile_with_directives file with
  | Ok out -> out
  | Error code ->
     CErrors.user_err ~loc (Pp.fmt "Compilation of %s failed with error %d." file code)

let infer_interface ~loc file =
  check_file ~loc file;
  match Compiler.infer_interface file with
  | Ok out -> out
  | Error code ->
     CErrors.user_err ~loc (Pp.fmt "Compilation of %s failed with error %d." file code)

let compile_scaffold ~loc mode scaffold =
  let build_file =
    match mode with
    | Snippet.Module (name, name_loc) ->
       check_module_name ~loc:name_loc name;
       begin match Build_files.save_module ~name scaffold with
       | Ok file -> file
       | Error err -> CErrors.user_err ~loc (Pp.str err)
       end
    | _ -> Build_files.save_snippet scaffold
  in
  match mode with
  | Check -> infer_interface ~loc build_file
  | Module (m, _) ->
     let compilation_output = compile_file ~loc build_file in
     Module_manager.declare_module m compilation_output;
     compilation_output
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

let interpret (mode: Snippet.execution_mode) Compiler.{ compiled_file; dependencies } =
  match mode with
  | Check ->
     (* Read the interface from the [.mli] file. *)
     let mli_file = compiled_file in
     let intf = read_interface mli_file in
     Feedback.msg_info (Pp.str intf)
  | Module _ ->
     (* Already handled by [Module_manager]. *)
     assert false
  | _ ->
     Loader.load_file ~public:false ~dependencies compiled_file
