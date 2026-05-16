Require Import Camltac.Camltac.

(** Tests for the "Camltac Load" vernacular. *)

Fail Camltac Load "does_not_exist.ml".

(** Successful load. *)
Camltac Load "test.ml".
