From Camltac Require Import Camltac.

(** To test backtracking, we use [Restart] in proof-mode instead of [Undo]
    because [Undo] says "cannot undo". *)
Set Warnings "-undo-batch-mode".

Goal True.
Proof.
  Camltac Module M := ocaml:{{let x = 1}}.
  Camltac Eval ocaml:{{ return M.x }}.
  Restart.
  Camltac Module M := ocaml:{{let x = 2}}.
  Camltac Eval ocaml:{{ return M.x }}.
  exact I.
Qed.
