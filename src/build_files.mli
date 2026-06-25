(** Methods for saving build artifacts. *)

(** {1 Build directories} *)

val build_dir : string
(** [build_dir] is the name of the directory that stores build artifacts. *)

val snippets_dir : string
(** [snippets_dir] is the name of the directory that stores snippets. *)

val modules_dir : string
(** [modules_dir] is the name of the directory that stores modules. *)

(** {1 Save methods} *)

val save_snippet : string -> string
(** [save_snippet scaffold] saves the contents of the scaffold
    to a fresh file in [snippets_dir]. *)

val save_module : string -> string
(** [save_module scaffold] saves the contents of the scaffold
    to a fresh file in [modules_dir]. *)

val save_ppx_driver : string -> string
(** [save_ppx_driver contents] saves the contents of the given PPX driver to a
    fresh file. *)
