Defining new tactics
====================

.. coq:: none

   Require Import Camltac.Camltac.

In Camltac, tactics are OCaml functions whose return type is `a tactic` (for some type `a`). For example, here's a tactic that prints the conclusion of the current goal:

.. coq::

   Camltac Module Print_conclusion := ocaml:{{
     let run () =
       let* goals = Proofview.Goal.goals in
       match goals with
       | [goal] ->
         let* goal in
         let conclusion = Proofview.Goal.concl goal in
         let* pp = Terms.Constr.print conclusion in
         Feedback.msg_info pp;
         return ()
       | _ ->
         fail (Pp.str "No goal focused")
   }}.

To run our tactic, we can use the `ocaml:` quotation in Ltac (and Ltac2):

.. coq::

   Goal forall x : nat, x = x.
   Proof.
     ocaml:(Print_conclusion.run ()). (* .unfold *)
     reflexivity.
   Qed.

…or use `Camltac Eval`, which evaluates a tactic and prints its result:

.. coq::

   Camltac Eval ocaml:(return (1 + 1)). (* .unfold *)

Similarly to `Ltac2 Eval`, `Camltac Eval` does not modify the current proof state.
