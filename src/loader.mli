(** Dynamic loading of shared libraries using {!Dynlink}. *)

(** {1 Loading shared libraries} *)

val is_loaded : Build_file.t -> bool
(** [is_loaded file] returns [true] if the file is dynlinked in the current
    program. *)

val load_file : ?dependencies:string list -> [`Public | `Private] -> Build_file.t -> unit
(** [load_file ?dependencies file] loads the given compiled file into the current Rocq
    context.

    @param dependencies (default = [[]])
      List of dependencies of the file to load before.

    @param public
      If [`Public], the compilation unit is available to subsequently loaded files.
 *)
