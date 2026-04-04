(** This file wraps the OCaml native compiler (ocamlopt), providing utilities to
    compile OCaml files to shared libraries that can be dynlinked. *)

val compile : string -> (string, int) result
(** [compile file] compiles the given OCaml [file] to a shared library,
    returning either the path to the compiled file on success, or the error code
    if compilation failed. *)
