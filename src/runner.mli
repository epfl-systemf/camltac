(** Methods for running arbitrary OCaml files and snippets. *)

(** [run_file ?env file] compiles and runs the given OCaml file in environment
    [env], where [file] is an absolute path. *)
val run_file : ?env:Runtime.Environment.t -> string -> unit

(** [run_code ?public ?env code] compiles and runs the given OCaml code in environment
    [env] by writing the code to a temporary file. The return value is the name
    of the temporary file.
    If [public] is set to [true], the compilation unit is available to subsequently files. *)
val run_code : ?public:bool -> ?env:Runtime.Environment.t -> string -> string
