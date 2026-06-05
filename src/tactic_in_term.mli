(** Support for tactic-in-terms ([Definition x := ocaml:(…)]. *)

(** This interface is minimalistic on purpose, as the implementation
    is not exposed to other modules. *)

val from_ocaml : Snippet.t -> Constrexpr.constr_expr
(** [from_ocaml snippet] embeds the given OCaml snippet (representing a tactic)
    in a term. *)
