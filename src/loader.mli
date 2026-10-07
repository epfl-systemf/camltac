(** Dynamic loading of shared libraries using [Dynlink]. *)

val load_file : public:bool -> ?dependencies:string list -> Build_file.t -> unit
(** [load_file ~public ?dependencies file] loads the given compiled file into the current Rocq
    context.

    @param public
      If [true], the compilation unit is available to subsequently loaded files.

    @param dependencies (default = [[]])
      List of dependencies of the file to load before.
 *)
