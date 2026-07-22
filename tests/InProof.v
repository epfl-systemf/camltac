From Camltac Require Import Camltac.

Goal True.
Proof.
  (* The "Camltac Run" command is marked as a kernel side-effect, so it gets run twice:
     - Once during the proof
     - Once at Qed time.
     This is because Qed backtracks the global state to the state before the
     proof, and thus all commands that can have a side-effect on the environment
     are re-run from that state.

     See https://rocq-prover.zulipchat.com/#narrow/channel/237658-MetaRocq/topic/running.20TemplateMonad.20inside.20a.20tactic/near/321351073
   *)
  Camltac Run ocaml:(Feedback.msg_info (Pp.str "This message is printed twice.")).
  exact I.
Qed.
