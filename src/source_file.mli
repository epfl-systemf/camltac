(** OCaml source files. *)

open Filesystem

(** {1 Source file}

    Source files contain the final scaffolded OCaml code that is
    compiled by Camltac. They are stored in [.camltac/sources] and
    copied to [.camltac/build] before compilation.

    Source files are not cleaned up after compilation, since they are
    useful both for debugging and for IDE support. *)

type t
(** A source file in the current workspace. *)

val create : workspace:Workspace.t -> file:string -> string -> t
(** [create ~workspace ~file contents] writes [contents] to a fresh
    source file in [workspace].

    Source files are organized in a predictable scheme, where the [n]-th
    snippet in the file is written to
    [.camltac/sources/<file.v>/<n>/<file>_<n>.ml].

    In interactive sessions, [create] may overwrite a previous source
    file after a backtrack, so that the above naming scheme is always
    followed. This prevents an explosion in the number of generated
    files (see #86).
 *)

val create_companion : workspace:Workspace.t -> name:string -> t -> string -> t
(** [create_companion ~workspace ~name source contents] writes
    [contents] to a companion file of [source]. The companion file has
    the given [name] and is placed in the same directory as [source] in
    [workspace].

    Unlike [create], this does not increase the internal snippet
    counter. *)

(** {2 Path resolution} *)

val path : t -> Path.t
(** [path source] returns the path of [source] relative to its
    workspace's [sources] directory. *)

val resolve : workspace:Workspace.t -> t -> Path.t
(** [resolve ~workspace source] returns the absolute path of [source],
    resolving it in [workspace]. *)
