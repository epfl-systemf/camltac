Require Import MLtac.MLtac.

(** Tests for the "MLtac Load" vernacular. *)

Fail MLtac Load "does_not_exist.ml".

(** Successful load. *)
MLtac Load "test.ml".

