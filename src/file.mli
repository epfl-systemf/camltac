(** Utilities for interacting with the file system. *)

exception Not_found
(** Exception raised when a file could not be found. *)

(** {1 Read/write} *)

val read : string -> string
(** [read filename] returns the contents of the given file.

    @raise Not_found if [filename] does not correspond to a file. *)
