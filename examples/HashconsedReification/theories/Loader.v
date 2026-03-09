From Ltac2 Require Import Ltac2.

Declare ML Module "HashconsedReification.plugin".

(** A function that reifies the given boolean term using OCaml. *)
Ltac2 @external ml_reify : constr -> constr := "HashconsedReification.plugin" "reify".

(** A function that reifies and hashconses the given boolean term using OCaml. *)
Ltac2 @external hashcons_reify : constr -> constr := "HashconsedReification.plugin" "hashcons_reify".
