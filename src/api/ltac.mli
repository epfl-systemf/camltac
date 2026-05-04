(** Ltac1 FFI *)

module FFI : sig
  val define : string -> unit Proofview.tactic -> unit
  (** [define name tac] registers the tactic [tac] to Ltac1. *)
end
