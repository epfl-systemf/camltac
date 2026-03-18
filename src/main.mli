val run_file : string -> unit
(** [run_file file] runs the given OCaml file in the current Rocq context. *)

val run_snippet : loc:Loc.t -> string -> unit
(** [run_snippet snippet] runs the given OCaml snippet in the current Rocq context. *)

val run_snippet_as_term : loc:Loc.t -> string -> Constrexpr.constr_expr_r
(** [run_snippet_as_term ~loc snippet] runs the given OCaml snippet in the current Rocq context,
    returning the output term. *)
