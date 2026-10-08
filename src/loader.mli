(** Dynamic loading of shared libraries using [Dynlink]. *)

val load_file : ?dependencies:string list -> [`Public | `Private] -> Build_file.t -> unit
(** [load_file ?dependencies file] loads the given compiled file into the current Rocq
    context.

    @param dependencies (default = [[]])
      List of dependencies of the file to load before.

    @param public
      If [`Public], the compilation unit is available to subsequently loaded files.
 *)
