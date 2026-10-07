(** Utilities for interacting with the file system. *)

exception Not_found
(** Exception raised when a file could not be found. *)

(** {1 Read/write} *)

val read : CUnix.physical_path -> string
(** [read filename] returns the contents of the given file.

    @raise Not_found if [filename] does not correspond to a file. *)

val write : file:CUnix.physical_path -> string -> unit
(** [write ~file contents] writes the given [contents] to [file], creating it if
    it does not exist, or overwriting its previous content. *)

(** {1 Module name} *)

val module_name : CUnix.physical_path -> string
(** [module_name file] returns the OCaml module name of the given
    file. *)
