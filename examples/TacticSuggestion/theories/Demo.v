From Ltac2 Require Import Ltac2.
From TacticSuggestion Require Import Loader.

From Stdlib Require Bool.

(* Here is an example of use in action: *)
Goal forall a b : bool, (andb a b) = (andb b a).
Proof.
  intros.
  apply?.
  apply Bool.andb_comm.
Qed.
