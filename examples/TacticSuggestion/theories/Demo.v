(*|
=================
Tactic suggestion
=================

This example plugin creates a `apply?` tactic that suggests theorem to be applied
in the current context, taking inspiration from `Lean's "Library Search" tactics`_.

.. _Lean's "Library Search" tactics: https://lean-lang.org/doc/reference/latest/Tactic-Proofs/Tactic-Reference/#tactic-ref-search
|*)

From Ltac2 Require Import Ltac2.
From TacticSuggestion Require Import Loader.

From Stdlib Require Bool.

(*|
Here is an example use in action:
|*)
Goal forall a b : bool, (andb a b) = (andb b a).
Proof.
  intros.
  apply?.
  apply Bool.andb_comm.
Qed.

