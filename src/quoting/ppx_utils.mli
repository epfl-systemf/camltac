(** Utility methods for manipulation PPX expressions and locations. *)

val loc_of_rocq_loc : Loc.t -> Ppxlib.Location.t
(** [loc_of_rocq_loc loc] converts a Rocq [Loc.t] into a Ppxlib [Location.t]. *)

val rocq_loc_of_loc : Ppxlib.Location.t -> Loc.t
(** [rocq_loc_of_loc loc] converts a Ppxlib [Location.t] to a Rocq [Loc.t]. *)

open Ppxlib

val with_let_bindings : loc:location -> (string loc * expression) list -> expression -> expression
(** [with_let_bindings ~loc bindings expr] wraps expression [expr] with the
    given list of named let-bindings.

    For example, [with_let_bindings ~loc [({ txt = "x"; … }, [%expr 0]); ({ txt = "y"; … }; [%expr 1])] [%expr x + y]]
    generates the code [let x = 0 in let y = 1 in x + y]. *)
