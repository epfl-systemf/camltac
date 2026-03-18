open Pp

let run_file file =
  match Compiler.compile file with
  | Ok out ->
     Loader.load_file out;
     Sys.remove out
  | Error err ->
     CErrors.user_err (fmt "Compilation of %s exited with error code %d." file err)

let run_snippet snippet =
  Temp_file.with_temp_file ~prefix:"snippet" ~suffix:".ml" snippet begin fun temp_file ->
    match Compiler.compile temp_file with
    | Ok out ->
       Loader.load_file out;
       Sys.remove out
    | Error err ->
       CErrors.user_err (fmt "Compilation of snippet exited with error code %d." err)
  end
