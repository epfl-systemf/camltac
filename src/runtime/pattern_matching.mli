(** Support for pattern matching on terms and goals. *)

open Api.Tactics

(** {1 Term matching} *)

type 'a case = pattern * 'a continuation
(** Type of cases in term matching. *)

and pattern = Constrexpr.constr_expr
(** Type of patterns in term pattern matching. *)

and 'a continuation = substitution -> 'a tactic
(** Type of continuations in a pattern matching branch. *)

and substitution = Ltac_pretype.patvar_map
(** Type of substitutions. *)

val match_term : EConstr.constr -> cases:'a case list -> 'a tactic
(** [match_term t ~cases] performs pattern matching on term [t] with
    backtracking. *)

val pattern_variables : pattern -> Pattern.patvar CAst.t list
(** [pattern_variables c] returns the names of pattern variables mentioned in
    [c]. *)
