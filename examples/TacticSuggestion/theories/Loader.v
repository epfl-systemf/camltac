From Ltac2 Require Import Ltac2.

Declare ML Module "TacticSuggestion.plugin".

(** A variant of apply that searches for lemmas that can be applied to the current goal. *)
Ltac2 @external apply_search : unit -> unit := "TacticSuggestion.plugin" "apply_search".

(** A notation similar to Lean's approach. *)
Ltac2 Notation "apply?" := apply_search ().
