(** Logical paths. *)

open Filesystem
open Names

(** {1 Logical paths}

    Rocq's [.vo] files must not contain absolute paths, since [.vo] may
    be relocated elsewhere (by [opam install], for example). Logical
    paths avoid this issue by representing paths relative to a logical
    root ({!DirPath.t}), which are resolved to physical paths using the
    {!Loadpath}.

    Before any call to {!Lib.add_leaf}, physical paths must be converted
    to logical paths. *)

type t
(** Type of logical paths. *)

val make : DirPath.t -> Path.t -> t
(** [make root path] creates a new logical path from the given [root],
    where [path] is relative to [root]. *)

val root : t -> DirPath.t
(** [root path] returns the logical root of [path]. *)

val path : t -> Path.t
(** [path logical_path] returns the physical path of [logical_path]
    relative to the root. *)

(** {2 Conversions to/from build files} *)

val to_build_file : t -> Build_file.t
(** [to_build_file path] resolves a logical path to a physical build
    file. *)

val of_build_file : Build_file.t -> t
(** [of_build_file file] converts a build file to a logical path that
    does not depend on the physical structure of the workspace. *)
