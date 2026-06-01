(** This file handles dynamic loading of compiled libraries
    by wrapping the [Dynlink] module from the OCaml standard library. *)

(** [load_file public file] loads the given compiled file into the current Rocq
    context. The file path must be absolute.
    If [public] is set to [true], the compilation unit is available to subsequent
    files. *)
val load_file : ?public:bool -> string -> unit
