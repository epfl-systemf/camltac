(** This file wraps the OCaml native compiler (ocamlopt), providing utilities to
    compile OCaml files to shared libraries that can be dynlinked. *)

val preprocess : string -> (string, int) result
(** [preprocess file] runs the MLtac preprocessor on the given file,
    returning the path to the preprocessed file, or the error code if
    preprocessing failed. *)

val compile : string -> (string, int) result
(** [compile file] compiles the given OCaml [file] to a shared library,
    returning either the path to the compiled file on success, or the error code
    if compilation failed. *)

(** Type of errors raised by [preprocessed_and_compile]. *)
type error =
  | Preprocessing_failed of int
  | Compilation_failed of int

val preprocess_and_compile : string -> (string, error) result
(** [preprocess_and_compile file] runs [preprocess file] and [compile] the
    resulting file. *)
