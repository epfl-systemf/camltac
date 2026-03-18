(** This file handles dynamic loading of compiled libraries
    by wrapping the [Dynlink] module from the OCaml standard library. *)

open Pp

(** List of extensions that can be loaded. *)
let allowed_extensions =
  if Dynlink.is_native then [".cmxs"] else [".cmo"; ".cma"]

(** Checks that the given [file] can be dynamically loaded. *)
let check_file file =
  if not (List.mem (Filename.extension file) allowed_extensions) then
    CErrors.user_err (fmt "File %s is not a %s file." file (String.concat " or " allowed_extensions))
  else if not (Sys.file_exists file) then
    CErrors.user_err (fmt "File %s does not exist." file)

let load_file file =
  check_file file;
  Feedback.msg_debug (fmt "Loading file %s." file);
  try
    Dynlink.loadfile_private file;
    Feedback.msg_debug (fmt "File %s successfully loaded." file);
  with Dynlink.Error e ->
    let message = Dynlink.error_message e in
    CErrors.user_err (str message)
