Require Import MLtac.MLtac.

(** Tests for OCaml-in-term quotations. *)

Check (1 + ocaml:(return ())). (* 1 + ltac:(idtac) *)

Goal nat.
Proof.
  pose (a := 1).
  pose (b := 2).
  refine ocaml:(
    let open Proofview in
    let* c = [%constr "a + b"] in
    Ltac2.exact_no_check c
  ).
Qed.

Goal forall x y, x = 1 /\ 1 = y -> x = y.
Proof.
  intros.
  refine ocaml:(Ltac2.etransitivity ()).
  all: destruct H; eassumption.
Qed.
