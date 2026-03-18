(** Defines registration methods for dynamically linked code. *)

(** Registers the given term as a new output. *)
val register_term : Constrexpr.constr_expr_r -> unit

(** Return the last registered term, or raises [Not_found]
    if there are no such terms. *)
val get_last_term : unit -> Constrexpr.constr_expr_r
 
