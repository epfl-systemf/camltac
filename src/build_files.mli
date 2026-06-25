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

val save_module : ?override:bool -> name:string -> string -> (string, string) result
(** [save_module ?override ~name scaffold] saves the contents of the scaffold
    to a file named [<name>.ml] in [modules_dir]. The result is either
    [Ok file], indicating success, or [Error message] if there is already a
    module with the same name and [override] is set to [false]. *)

val save_ppx_driver : string -> string
(** [save_ppx_driver contents] saves the contents of the given PPX driver to a
    fresh file. *)
