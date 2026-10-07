(** Build artifacts. *)

(** {1 Build files} *)

(** A build file is a file in a build directory. *)
type t = private
  { root : Layout.root;        (** Root of the layout where the build file is installed. *)
    path : CUnix.physical_path (** Path relative to [root]. *)
  }

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
(** [module_name file] is equivalent to [File.module_name (locate build_file)]
    but more efficient. *)

(** {1 Creation} *)

(** Kind of build files. *)
type kind = Snippet | Module | Ppx_driver

val write : kind:kind -> string -> t
(** [write ~kind contents] saves the given contents to a fresh build file. The
    exact location where the file is saved depends on [kind]. *)
