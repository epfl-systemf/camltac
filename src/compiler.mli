(** This file wraps the OCaml compiler (ocamlc/ocamlopt), providing utilities
    to compile to shared libraries that can be dynlinked. *)

val lowlevel_compile : ?extra_args:string list -> string -> (string, int) result
(** [lowlevel_compile ?extra_args file] compiles the given OCaml [file] to a shared library,
    returning either the path to the compiled file on success, or the error code
    if compilation failed. [extra_args] is a list of additional arguments to
    pass to the compiler. *)

val compile : string -> (string, int) result
(** [compile file] compiles [file], following Camltac annotations. *)
