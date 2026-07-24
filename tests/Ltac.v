(** Tests for OCaml in Ltac. *)

From Camltac Require Import Camltac.

Goal forall x : nat, x = x.
Proof.
  ocaml:(Ltac2.reflexivity).
Qed.
