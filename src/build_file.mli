(** Build artifacts. *)

(** {1 Build files}

    A build file is a file in a build directory, i.e., in a specific
    {!Layout.t}. Build files are used to temporarily store source files and
    build artifacts, such as compiled libraries or executables.
 *)

type t
(** Type of build files.

    Build files are physical, so they must not be written to [.vo] files
    directly. Use {!Logical_path} for that purpose.
 *)

val unsafe_of_path : root:CUnix.physical_path -> CUnix.physical_path -> t
(** [unsafe_of_path ~root path] creates a build file from a [root] and
    a [path] relative to [root]. The file is not checked for existence. *)

val root : t -> CUnix.physical_path
(** [root file] returns the root of the layout of [file]. *)

val relative_path : t -> CUnix.physical_path
(** [relative_path file] returns the path of [file] relative to its root. *)

val layout : t -> Layout.t
(** [layout file] returns the layout which includes the build file. *)

val locate : t -> CUnix.physical_path
(** [locate file] looks for the given [file] by locating it in the build
    directory where it was originally created. *)

val path : t -> CUnix.physical_path
(** [path file] returns the physical path of [file]. Contrary to [locate file],
    [path file] does not check that the file exists. *)

val with_extension : t -> string -> t
(** [with_extension file ext] returns a build file that has the same path as
    [file] but with extension [ext] instead. *)

val module_name : t -> string
(** [module_name file] is equivalent to [Filesystem.Path.module_name (locate file)] but
    more efficient. *)

(** {1 Read/write} *)

val read : t -> string
(** [read file] reads the given build file. *)

(** Kind of build files. *)
type kind = Snippet | Module | Ppx_driver

val write : kind:kind -> string -> t
(** [write ~kind contents] saves the given contents to a fresh build file. The
    exact location where the file is saved depends on [kind]. *)
