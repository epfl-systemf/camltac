Pattern matching over terms
===========================

.. coq:: none

   Require Import Camltac.Camltac.

Just like Ltac2, Camltac provides the ability to perform pattern-matching on terms using the `match%rocq` syntax:

.. coq::

   Inductive nat' :=
     | NatZero
     | NatSucc (n : nat')
     | NatMul (n1 n2 : nat').

   Camltac Module Reify := ocaml:{{
     let rec reify n =
       match%rocq n with
       | {| 0 |} -> {%constr| NatZero |}
       | {| S ?m |} ->
         let* m' = reify m in
         {%constr| NatSucc %{m'} |}
       | {| ?n1 * ?n2 |} ->
         let* n1' = reify n1 in
         let* n2' = reify n2 in
         {%constr| NatMul %{n1'} %{n2'} |}
   }}.

   Camltac Eval ocaml:{{
     let* n = {%constr| 2 * 3 |} in
     Reify.reify n
   }}. (* .unfold *)

The left-hand side of each branch is a pattern with pattern variables of the form `?name`. Each pattern variable is associated to an OCaml variable of the same name, which makes the syntax similar to Ltac2's `match!`.

Note that `match%rocq` is backtracking, meaning that branches are tried in order until one of them succeeds. We also support `match%lazy` and `match%multi` for non-backtracking and multi-success pattern matching, as in Ltac2.
