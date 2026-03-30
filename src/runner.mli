(** Methods for running arbitrary OCaml files and snippets. *)

(** [run_file file] compiles and runs the given OCaml file, where [file]
    is an absolute path. *)
val run_file : string -> unit

(** [run_code ?env code] compiles and runs the given OCaml code in environment
    [env] by writing the code to a temporary file. *)
val run_code : ?env:Runtime.Environment.t -> string -> unit
