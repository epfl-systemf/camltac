val run_file : string -> unit
(** [run_file file] compiles and runs the given OCaml file. *)

val run_snippet : string -> unit
(** [run_snippet snippet] compiles and runs the given OCaml snippet by
    creating a temporary file. *)
