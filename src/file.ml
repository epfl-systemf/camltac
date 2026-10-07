(** Utilities for interacting with the file system. *)

exception Not_found
(** Exception raised when a file could not be found. *)

(** {1 Read/write} *)

let read filename =
  try In_channel.with_open_text filename In_channel.input_all
  with Sys_error _ when Sys.file_exists filename ->
    raise Not_found

let write ~file contents =
  Out_channel.with_open_text file (fun oc -> output_string oc contents)

(** {1 Utilities} *)

let module_name filename =
  Filename.basename filename
  |> Filename.remove_extension
  |> String.capitalize_ascii
