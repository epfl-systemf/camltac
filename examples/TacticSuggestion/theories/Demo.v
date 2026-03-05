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

(*|
Notes
=====

What we wish for is roughly the following embed OCaml tactic:

.. code:: ocaml

   Goal.enter_one begin fun goal ->
     let conclusion = Goal.conclusion goal in
     let pattern = Pattern.of_econstr goal conclusion in
     let results = Command.SearchPattern.run ~goal conclusion in
     let message =
       if List.is_empty results then Message.error "No theorem could be applied."
       else Message.message
              ~trim:true
              "Here is the list of theorems that could be applied: %s"
              (results |> List.map SearchResult.print |> Message.join Message.new_line)
     in Message.print message
   end
|*)
