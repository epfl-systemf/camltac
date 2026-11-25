(** Currently-compiling library.

    The "current library" refers to the library [.v] file being compiled
    in this Rocq process. *)

open Names

(** {1 Compilation information} *)

val top_module_name : unit -> string
(** [top_module_name ()] returns the top Rocq module name of the library.
    This function is affected by the [-top] option. *)

val parent : unit -> DirPath.t
(** [parent ()] returns the parent of the currently-compiling library.
    [parent ()] may return an empty path in the toplevel. *)

val cwd : unit -> CUnix.physical_path
(** [cwd ()] returns the current working directory of the library file.
    In the toplevel, this is equivalent to {!Sys.getcwd}. *)
