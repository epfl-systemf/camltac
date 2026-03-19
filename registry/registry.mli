(** Defines registration methods for dynamically linked code. *)

(** Registers the given term as a new output. *)
val register_term : Constrexpr.constr_expr_r -> unit

(** Return the last registered term, or raises [Not_found]
    if there are no such terms. *)
val get_last_term : unit -> Constrexpr.constr_expr_r
 
val register : string -> 'a -> unit
(** [register name v] registers value [v] with key [name] in the
    registry. *)

val find : string -> 'a
(** [find name] finds the value with name [name] in the registry.
    WARNING: This function breaks type safety, and should be used
    only when the expected type is known. *)

