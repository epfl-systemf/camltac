Require Import Camltac.Camltac.
Require Import Ltac2.Ltac2.

(** OCaml in Ltac2 *)

Ltac2 zero () := ocaml:(let* zero = [%constr "0"] in Ltac2.exact_no_check zero).

Definition zero := ltac2:(zero ()).
Print zero.
