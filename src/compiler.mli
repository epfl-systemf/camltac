(** This file wraps the OCaml native compiler (ocamlopt),
    providing utilities to compile to shared libraries that can be dynlinked. *)

val compile : string -> (string, int) result
(** [compile file] compiles the given OCaml [file] to a shared library, returning
    the path to the compiled file, or the error code if compilation failed. *)
