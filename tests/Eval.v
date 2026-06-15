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
