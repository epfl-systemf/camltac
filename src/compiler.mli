(** Compilation of OCaml snippets to shared libraries. *)

(** Type of compilation output. *)
type output =
  { compiled_file: Build_file.t;
    dependencies: string list
  }

type context =
  { alias_module: string option; (** A module containing module aliases. *)
    dependencies: string list;     (** List of already loaded dependencies. *)
    modules_dirs: string list;     (** List of modules directories to include. *)
  }

val compile :
  ?context:context ->
  directives:Build_directives.t ->
  Ocamlfind.mode ->
  Build_file.t ->
  (output, int) result
(** [compile ?context ~directives mode file] compiles [file] according to
    [mode] in the given [context]. *)
