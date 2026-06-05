(** Dynamic loading of shared libraries using [Dynlink]. *)

val load_packages : string list -> unit
(** [load_packages packages] loads the given list of packages. *)

val load_file : public:bool -> ?dependencies:string list -> string -> unit
(** [load_file ~public ?dependencies file] loads the given compiled file into the current Rocq
    context. The file path must be absolute.

    @param public
      If [true], the compilation unit is available to subsequently loaded files.

    @param dependencies (default = [[]])
      List of dependencies of the file to load before.
 *)
