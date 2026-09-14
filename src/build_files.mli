(** Methods for saving build artifacts. *)

(** {1 Build directories} *)

val root_dir : string
(** [root_dir] is the parent of [build_dir]. *)

val build_dir : string
(** [build_dir] is the path of the [.camltac] directory. *)

val snippets_dir : string
(** [snippets_dir] is the path of the directory that stores snippets. *)

val modules_dir : string
(** [modules_dir] is the path of the directory that stores modules. *)

(** {1 Write methods} *)

val write_snippet : string -> string
(** [write_snippet contents] saves the contents of the snippet
    to a fresh file in [snippets_dir]. *)

val write_module : string -> string
(** [write_module contents] saves the contents of the module
    to a fresh file in [modules_dir]. *)

val write_ppx_driver : string -> string
(** [write_ppx_driver contents] saves the contents of the given PPX driver to a
    fresh file. *)
