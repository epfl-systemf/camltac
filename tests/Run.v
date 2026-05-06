Require Import MLtac.MLtac.

(** Test for the "MLTac Run" command. *)

MLtac Run ocaml:(Feedback.msg_info (Pp.str "This message should be printed!")).
Fail MLtac Run ocaml:(CErrors.user_err (Pp.str "This message should be an error!")).

(** Tests for failing compilations. *)
(* TODO: Uncomment once we capture OCaml errors. *)
(* Fail MLtac Run ocaml:(1 ^ "x"). *)
