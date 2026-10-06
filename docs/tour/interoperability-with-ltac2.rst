Interoperability with Ltac2
===========================

.. coq:: none

   Require Import Camltac.Camltac.

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

Tactics in Camltac can be exposed to Ltac2 using the `FFI` module:

.. coq::

   Require Import Ltac2.Ltac2.

   Camltac Run ocaml:{{
     (* We expose our previously defined reification procedure to Ltac2: *)
     Ltac2.FFI.(define "reify"
                 (constr @-> tac constr)
                 Reify.reify)
   }}.

   Ltac2 @external reify : constr -> constr :=
     "rocq-camltac.plugin.runtime" "reify".

   Ltac2 Eval (reify constr:(2 * 3)). (* .unfold *)
