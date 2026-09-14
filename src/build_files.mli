(** Methods for saving build artifacts. *)

(** {1 Build files} *)

type t
(** A build file is a file in a build directory.

    This type is marshable and can be used by a different process,
    even if its value of [build_dir] differs. This is implemented
    by recording the current [build_dir], thus making [Build_files.t] values
    layout-independent.
 *)

val of_path : CUnix.physical_path -> t
(** [of_path path] checks whether [path] corresponds to a build file, and if so,
    converts it to the correct representation.

    @raise InvalidArgument if [path] is not a build file.
 *)

val locate : t -> CUnix.physical_path
(** [locate build_file] returns the absolute path of [build_file] by locating it
    in the build directory where the file was originally created. *)

(** {1 Build directories} *)

val build_dir : ?file:t -> unit -> CUnix.physical_path
(** [build_dir ?file ()] is the path of the [.camltac] directory of
    [file], if specified, or the current [.camltac] directory otherwise. *)

val modules_dir : ?file:t -> unit -> CUnix.physical_path
(** [modules_dir ?file ()] is the path of the build directory that stores
    modules, as a subdirectory of [build_dir ?file ()]. *)

(** {1 Write methods} *)

val write_snippet : string -> t
(** [write_snippet contents] saves the contents of the snippet
    to a fresh build file in [snippets_dir]. *)

val write_module : string -> t
(** [write_module contents] saves the contents of the module
    to a fresh build file in [modules_dir]. *)

val write_ppx_driver : string -> t
(** [write_ppx_driver contents] saves the contents of the given PPX driver to a
    fresh build file. *)
