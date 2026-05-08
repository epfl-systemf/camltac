(** Utility methods for manipulation PPX expressions and locations. *)

open Ppxlib

val rocq_loc_of_loc : location -> expression
(** [rocq_loc_of_loc loc] converts a Ppxlib [location] to an expression
    representing a Rocq [Loc.t]. *)

val with_let_bindings : loc:location -> (string loc * expression) list -> expression -> expression
(** [with_let_bindings ~loc bindings expr] wraps expression [expr] with the
    given list of named let-bindings.

    For example, [with_let_bindings ~loc [({ txt = "x"; … }, [%expr 0]); ({ txt = "y"; … }; [%expr 1])] [%expr x + y]]
    generates the code [let x = 0 in let y = 1 in x + y]. *)
