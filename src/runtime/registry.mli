(** Defines registration methods for dynamically linked code. *)


val register_output : 'a -> unit
(** Registers the given output. *)

val get_last_output : unit -> 'a
(** Return the last output, or raises [Not_found] if there
    is no such output. *)
