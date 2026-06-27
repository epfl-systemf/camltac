(*|
===================
Reifying stdpp maps
===================
|*)

From Camltac Require Import Camltac.
From Ltac2 Require Import Ltac2.
From stdpp Require Import gmap.

From Stdlib Require Import String.
Open Scope string.

(*|
First, we need an inductive data type as the target of our reification procedure:
|*)

Inductive map {K V : Type} :=
| MapEmpty
| MapInsert (k : K) (v : V) (m : map)
| MapUnion (m1 m2 : map).

(*|
Our main reification procedure then maps every operation on `gmap` to its corresponding
reified constructor:
|*)

Camltac Run ocaml:{{
  let rec reify x =
    match%rocq x with
    | "empty" -> {%open_constr| MapEmpty |}
    | "insert ?k ?v ?m" ->
      let* m' = reify m in
      {%constr| MapInsert %{k} %{v} %{m'} |}
    | "union ?m1 ?m2" ->
      let* m1' = reify m1 in
      let* m2' = reify m2 in
      {%constr| MapUnion %{m1'} %{m2'} |}

  (* Now, we expose it to Ltac2 as follows: *)
  let _ = FFI.(define "reify" (constr @-> tac constr) reify)
}}.

(*|
… and we can immediately use it!
|*)
Ltac2 @external reify : constr -> constr := "camltac.plugin.runtime" "reify".

Ltac2 Eval (reify constr:(insert 0 "Hello" (insert 1 "World" empty) : gmap nat string)).
(* - : constr = constr:(MapInsert 0 "Hello" (MapInsert 1 "World" MapEmpty)) *)
