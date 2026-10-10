val set_tactic : 'a Proofview.tactic -> unit
(** [set_tactic tac] sets the result of the interpretation of an
    OCaml-in-term/OCaml-in-Ltac tactic to [tac].

    WARNING: This is an internal function that is used by the runtime; do not
    call it yourself! *)

val get_tactic : unit -> 'a Proofview.tactic
(** [get_tactic ()] returns the last OCaml tactic set through [set_tactic].

    WARNING: This is an internal function that is used by the runtime; do not
    call it yourself! *)

val register_module : string -> (unit -> unit) -> unit
(** [register_module m f] registers module initializers of [m] as the thunk [f].
    A typical usage is of the form [register_module "name" (fun () -> let module _ = Make () in ())].

    WARNING: This is an internal function that is used by the runtime; do not
    call it yourself! *)

val get_module : string -> (unit -> unit)
(** [get_module m] returns the module initializer function of [m] as registered
    through {!register_module}, or [Fun.id] otherwise.

    WARNING: This is an internal function that is used by the runtime; do not
    call it yourself! *)
