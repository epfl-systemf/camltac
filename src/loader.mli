(** This file handles dynamic loading of compiled libraries
    by wrapping the [Dynlink] module from the OCaml standard library. *)

(** [load_file file] loads the given compiled file into the current Rocq
    context. The file path must be absolute. *)
val load_file : string -> unit
