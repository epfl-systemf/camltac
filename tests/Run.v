Require Import Camltac.Camltac.

(** Test for the "Camltac Run" command. *)

Camltac Run ocaml:(Feedback.msg_info (Pp.str "This message should be printed!")).
Fail Camltac Run ocaml:(CErrors.user_err (Pp.str "This message should be an error!")).

(** Tests for failing compilations. *)
(* TODO: Uncomment once we capture OCaml errors. *)
(* Fail Camltac Run ocaml:(1 ^ "x"). *)
