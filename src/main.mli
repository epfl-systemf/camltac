(** Main entry point of MLtac. *)

(** Run the given OCaml file in the current Rocq context. *)
val run_file : string -> unit

(** Runs the given OCaml snippet in the current Rocq context. *)
val run_snippet : Snippet.t -> unit
