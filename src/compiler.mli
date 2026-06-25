(** Compilation of OCaml snippets to shared libraries. *)

(** Type of compilation output. *)
type output =
  { compiled_file: string;
    dependencies: string list
  }

val compile_with_directives : ?packing_module:string -> string -> (output, int) result
(** [compile file] compiles [file] to a shared library that can be loaded through [Loader.load_file].
    Build directives are recognized by this method, and integrated in the compilation process.

    If [packing_module] is not [None], it is added to the list of opened modules. *)

val infer_interface : ?packing_module:string -> string -> (output, int) result
(** [infer_interface file] type-checks [file] and returns its inferred interface. *)
