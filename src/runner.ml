open Pp

(** [run ?env ~name file] compiles and loads [file] in environment [env].
    [name] is used in error messages. *)
let run ?public ?(env = Runtime.Environment.empty) ~name file =
  match Compiler.compile file with
  | Ok out ->
     Runtime.Environment.set_env env;
     Loader.load_file ?public out;
     Sys.remove out;
     Runtime.Environment.unset_env ()
  | Error err ->
     CErrors.user_err (fmt "Compilation of %s exited with error code %d." name err)

let run_file ?env file =
  if Sys.file_exists file then
    run ?env ~name:(Filename.basename file) file
  else
    CErrors.user_err (fmt "File %s does not exist." file)

let run_code ?public ?env code =
  Tempfile.with_temp_file
    ~prefix:"snippet"
    ~suffix:".ml"
    code
    (fun temp_file -> run ?public ?env ~name:"snippet" temp_file; temp_file)
