val run_file : string -> unit
(** [run_file file] runs the given OCaml file in the current Rocq context. *)

val run_snippet : Snippet.t -> unit
(** [run_snippet snippet] runs the given OCaml snippet in the current Rocq context. *)

val run_snippet_as_term : Snippet.t -> Constrexpr.constr_expr_r
(** [run_snippet_as_term snippet] runs the given OCaml snippet in the current Rocq context,
    returning the output term. *)
