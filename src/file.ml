(** Utilities for interacting with the file system. *)

exception Not_found
(** Exception raised when a file could not be found. *)

(** {1 Read/write} *)

let read filename =
  if Sys.file_exists filename then
    In_channel.with_open_text filename In_channel.input_all
  else
    raise Not_found
