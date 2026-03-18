(** Run the given OCaml file in the current Rocq context. *)
val run_file : string -> unit

(** Run the given OCaml snippet in the current Rocq context. *)
val run_snippet : loc:Loc.t -> string -> unit

(** Run the given OCaml snippet in the current Rocq context,
    returning the output term. *)
val run_snippet_as_term : loc:Loc.t -> string -> Constrexpr.constr_expr_r
