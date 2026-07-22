Require Import Camltac.Camltac.

Camltac Eval ocaml:{{ return "Hello" }}.
Camltac Eval ocaml:([%constr "1 + 1"]).
Camltac Eval ocaml:([%open_constr "?[x]"]).
Camltac Eval ocaml:([%constr "forall x : nat, x = S x"]).
Camltac Eval ocaml:(return [%expr "x"]).

Require Import Ltac2.Ltac2.

Ltac2 Eval ("Hello").
Ltac2 Eval (constr:(1 + 1)).
Ltac2 Eval ('(?[x])).
Ltac2 Eval (constr:(forall x : nat, x = S x)).

(** Eval in proof *)
Goal forall x : nat, True.
Proof.
  intros.
  Camltac Eval ocaml:{{
    let* env = Tactics.env in
    return (Result.get_ok @@ Ltac2.Control.hyp env {%ident| x |})
  }}.
  exact I.
Qed.
