val set_tactic : unit Proofview.tactic -> unit
(** [set_tactic tac] sets the result of the interpretation of an
    OCaml-in-term/OCaml-in-Ltac tactic to [tac].

    WARNING: This is an internal function that is used by the runtime; do not
    call it yourself! *)

val get_tactic : unit -> unit Proofview.tactic
(** [get_tactic ()] returns the last OCaml tactic set through [set_tactic].

    WARNING: This is an internal function that is used by the runtime; do not
    call it yourself! *)
