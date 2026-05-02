(** Utility methods for manipulation PPX expressions and locations. *)

open Ppxlib

val expr_of_list : loc:location -> expression list -> expression
(** [expr_of_list ~loc list] constructs a single list expression from the given list
    of expressions. *)
