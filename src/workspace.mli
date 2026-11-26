(** Physical workspace. *)

open Filesystem

(** {1 Workspace}

    The workspace is the place where Camltac stores its working
    files. It consists of a special [.camltac] directory, divided
    between source files ({!Source_file.t}) and build files
    ({!Build_file.t}).
 *)

type t
(** Type of workspaces. *)

val at : Path.t -> t
(** [at dir] returns the workspace in directory [dir], creating
    it if necessary. *)

val camltac_dir_name : string
(** The name of the Camltac directory (i.e. [.camltac]). *)

val sources_dir_name : string
(** The name of the sources directory (i.e. [sources]). *)

val build_dir_name : string
(** The name of the build directory (i.e. [build]). *)

(** {2 Path resolution} *)

val root : t -> Path.t
(** [root workspace] returns the root directory of the workspace. *)

val resolve : Path.t -> t -> Path.t
(** [resolve path workspace] resolves the relative [path] against the
    root of [workspace]. *)
