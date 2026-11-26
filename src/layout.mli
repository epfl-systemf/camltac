(** Build directories layout. *)

(** {1 Physical layouts} *)

(** Layout for build directories. *)
type t = private
 { root     : CUnix.physical_path; (** Root of the layout. *)
   build    : CUnix.physical_path; (** Path where build artifacts are stored (i.e., the [.camltac] directory). *)
   snippets : CUnix.physical_path; (** Path where snippets are stored. *)
   modules  : CUnix.physical_path; (** Path where modules are stored. *)
   ppx      : CUnix.physical_path; (** Path where PPX drivers are stored. *)
 }

val camltac_dir : string
(** Name of the directory that contains the build artifacts, relative to
    the layout's root. *)

val of_root : CUnix.physical_path -> t
(** [of_root root] returns the layout from the given [root]. *)

val current : unit -> t
(** [current ()] returns the layout for the currently compiling Rocq file. The
    layout is rooted at the physical location of the file's logical
    directory, or at the current directory for top-level files. *)
