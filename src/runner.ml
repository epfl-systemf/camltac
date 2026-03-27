open Pp

(** [run ~name file] compiles and loads [file].
    [name] is used in error messages. *)
let run ~name file =
  match Compiler.compile file with
  | Ok out ->
     Loader.load_file out;
     Sys.remove out
  | Error err ->
     CErrors.user_err (fmt "Compilation of %s exited with error code %d." name err)

let run_file file =
  run ~name:file file

let run_code code =
  Tempfile.with_temp_file
    ~prefix:"snippet"
    ~suffix:".ml"
    code
    (fun temp_file -> run ~name:"snippet" temp_file)
  
