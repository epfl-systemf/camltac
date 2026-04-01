open Ltac2_plugin

(** Defines registration methods for dynamically linked code. *)


val register_output : 'a -> unit
(** Registers the given output. *)

val get_last_output : unit -> 'a
(** Return the last output, or raises [Not_found] if there
    is no such output. *)
 
val register : string -> 'a -> unit
(** [register name v] registers value [v] with key [name] in the
    registry. *)

val find : string -> 'a
(** [find name] finds the value with name [name] in the registry.
    WARNING: This function breaks type safety, and should be used
    only when the expected type is known. *)

val register_ltac : string -> unit Proofview.tactic -> unit
(** [register_ltac name tac] registers tactic [tac] as name [f]. *)

val register_ltac2 : string -> ('a, 'f) Tac2externals.spec -> 'f -> unit
(** [register_ltac2 name spec f] registers function [f] as an Ltac2 function. Note that you need an Ltac2 @external to use this function. *)
