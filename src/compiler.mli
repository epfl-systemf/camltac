(** Compilation of OCaml snippets to shared libraries. *)

(** Type of compilation output. *)
type output =
  { compiled_file: string;
    dependencies: string list
  }

val compile_with_directives : string -> (output, int) result
(** [compile file] compiles [file] to a shared library that can be loaded through [Loader.load_file].
    Build directives are recognized by this method, and integrated in the compilation process. *)

val infer_interface : string -> (output, int) result
(** [infer_interface file] type-checks [file] and returns its inferred interface. *)
