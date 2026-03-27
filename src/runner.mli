(** Methods for running arbitrary OCaml files and snippets. *)

(** [run_file file] compiles and runs the given OCaml file, where [file]
    is an absolute path. *)
val run_file : string -> unit

(** [run_snippet snippet] compiles and runs the given OCaml snippet by
    creating a temporary file. *)
val run_snippet : string -> unit
