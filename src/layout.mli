(** Build directories layout. *)

open Names

(** {1 Layout root} *)

(** The root of the layout describes how build directories
    and artifacts are resolved. *)
type root =
  | Logical of DirPath.t
  (** Build artifacts are resolved relative to the logical path.

      Used by [rocq c]. This mode supports relocation of build artifacts. *)

  | Physical of CUnix.physical_path
  (** Build artifacts are stored at the given physical location.

      Used by [rocq top] and IDEs. *)

val current_root : unit -> root
(** [current_root ()] returns the root of the current layout. *)

val resolve : root -> CUnix.physical_path -> CUnix.physical_path
(** [resolve root file] resolves the given physical path against the
    root, checking for file existence.

    @raise UserErr if [file] does not resolve to a file. *)

val path : root -> CUnix.physical_path -> CUnix.physical_path
(** [path root file] resolves the [file] against the root and
    returns the obtained full path. *)

(** {1 Layouts} *)

(** Layout for build directories. *)
type t = private
 { root     : root;                (** Root of the layout. *)
   build    : CUnix.physical_path; (** Path where build artifacts are stored (i.e., the [.camltac] directory). *)
   snippets : CUnix.physical_path; (** Path where snippets are stored. *)
   modules  : CUnix.physical_path; (** Path where modules are stored. *)
   ppx      : CUnix.physical_path; (** Path where PPX drivers are stored. *)
 }

val of_root : root -> t
(** [of_root root] returns the layout from the given [root]. *)

val current : unit -> t
(** [current ()] returns the layout for the currently compiling Rocq file. *)
