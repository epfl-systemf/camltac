(** Build files. *)

open Filesystem

(** {1 Build files}

    A build file is a file used as an input or output of the compilation
    process. Build files are stored in the [.camltac/build] directory. *)

type t
(** Type of build files. *)

val workspace : t -> Workspace.t
(** [workspace file] returns the workspace that the build file belongs
    to. *)

val path : t -> Path.t
(** [path file] returns the relative path of the file in its
    workspace. *)

(** {2 Creating build files} *)

val copy_source : workspace:Workspace.t -> loaded_units:CString.Set.t -> Source_file.t -> t
(** [copy_source ~workspace ~loaded_units source] copies the [source]
    file to the build directory in [workspace] to prepare it for
    compilation.

    The contents of the source file are written to a fresh file in a
    subdirectory of [.camltac/build] that mirrors the directory structure
    of the source file. For example, [.camltac/sources/A/0/A0.ml] is
    copied to [.camltac/build/A/0].

    Since {!Loader.load_file} cannot load units with the same name
    twice, the build file name includes a random part that guarantee it
    is distinct from any of the [loaded_units].

    Earlier copies of the same source, along with their compilation
    products, are deleted. *)

val generate : workspace:Workspace.t -> dir:string -> name:string -> string -> t
(** [generate ~workspace ~dir ~name contents] creates a build file in
    the [dir] subdirectory of [.camltac/build], with the given [name]
    and [contents].

    A typical use-case of this method is for generated files that do not
    have a source file, e.g., PPX drivers. *)

val with_extension : string -> t -> t
(** [with_extension ext file] returns the build file [file'] such that
    [resolve file' = Filename.remove_extension (resolve file) ^ ext]. *)

(**/**)

val unsafe_of_path : workspace:Workspace.t -> Path.t -> t
(** [unsafe_of_path ~workspace path] returns the build file in [workspace] that
    has the given [path].

    It is unsafe in the sense that the file is not checked for existence, nor is
    it checked that the file is in the [.camltac/build] directory. *)

(**/**)

(** {2 Path resolution} *)

val resolve : t -> Path.t
(** [resolve file] returns the absolute path of [file]. *)
