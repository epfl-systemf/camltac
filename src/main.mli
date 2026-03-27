(** Main entry point of MLtac. *)

(** Run the given OCaml file in the current Rocq context. *)
val run_file : string -> unit

(** Runs the given OCaml snippet in the current Rocq context. *)
val run_snippet : Snippet.t -> unit

(** Runs the given OCaml snippet in the current Rocq context,
    returning the output term. *)
val run_snippet_as_term : Snippet.t -> Constrexpr.constr_expr_r
