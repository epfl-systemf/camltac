(** Methods for saving build artifacts. *)

(** {1 Build files} *)

type t
(** A build file is a file in a build directory.

    This type is marshable and can be used by a different process,
    even if its value of [build_dir] differs. This is implemented
    by recording the current [build_dir], thus making [Build_files.t] values
    layout-independent.
 *)

(** Kind of build files. *)
type kind = Snippet | Module | Ppx_driver

val write : kind -> string -> t
(** [write kind contents] saves the given contents to a fresh build file.
    The exact location where the file is saved depends on [kind]. *)

val with_extension : t -> string -> t
(** [with_extension build_file ext] returns a build file with the given
    extension. *)

val locate : t -> CUnix.physical_path
(** [locate build_file] returns the absolute path of [build_file] by locating it
    in the build directory where the file was originally created. *)

val module_name : t -> string
(** [module_name build_file] returns the module name of [build_file].

    Equivalent to [File.module_name (locate build_file)] but more efficient. *)

(** {1 Build directories} *)

val build_dir : ?file:t -> unit -> CUnix.physical_path
(** [build_dir ?file ()] is the path of the [.camltac] directory of
    [file], if specified, or the current [.camltac] directory otherwise. *)

val modules_dir : ?file:t -> unit -> CUnix.physical_path
(** [modules_dir ?file ()] is the path of the build directory that stores
    modules, as a subdirectory of [build_dir ?file ()]. *)
