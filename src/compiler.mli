(** This file wraps the OCaml compiler (ocamlc/ocamlopt), providing utilities
    to compile to shared libraries that can be dynlinked. *)

val compile : ?extra_args:string list -> string -> (string, int) result
(** [compile ?extra_args file] compiles the given OCaml [file] to a shared library,
    returning either the path to the compiled file on success, or the error code
    if compilation failed. [extra_args] is a list of additional arguments to
    pass to the compiler. *)

(** Type of errors raised by [preprocess_and_compile]. *)
type error =
  | Preprocessing_failed of int
  | Compilation_failed of int

val preprocess_and_compile : string -> (string, error) result
(** [preprocess_and_compile file] runs [preprocess file] and [compile] the
    resulting file. *)
