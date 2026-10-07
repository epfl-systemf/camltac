(** Compilation of OCaml snippets to shared libraries. *)

(** Type of compilation output. *)
type output =
  { compiled_file: Build_file.t;
    dependencies: string list
  }

type context =
  { packing_module: string option; (** A module containing module aliases. *)
    dependencies: string list;     (** List of already loaded dependencies. *)
    modules_dirs: string list;     (** List of modules directories to include. *)
  }

val compile_with_directives : ?context:context -> Build_file.t -> (output, int) result
(** [compile file] compiles [file] to a shared library that can be loaded through [Loader.load_file].
    Build directives are recognized by this method, and integrated in the compilation process.
 *)

val infer_interface : ?context:context -> Build_file.t -> (output, int) result
(** [infer_interface file] type-checks [file] and returns its inferred interface. *)
