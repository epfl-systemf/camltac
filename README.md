# Camltac: OCaml as a Tactic Language

Camltac allows OCaml to be written directly with Rocq scripts. It supports most constructs from Ltac2, including term construction (`constr:(…)`), pattern matching, and antiquotations using [`ppx_rocq`](https://github.com/epfl-systemf/ppx_rocq), and more. Moreover, Camltac ships with most of the [Ltac2 API](https://rocq-prover.org/doc/master/corelib/index.html#Ltac2), which guarantee stability across Rocq versions.

See the [quickstart](#quickstart) section for ready-to-use examples.

## Setup

To install Camltac from sources, clone the repo and run `opam install .`, as follows:

```sh
git clone git@github.com:epfl-systemf/camltac.git
cd camltac
opam install .
```

Then, add `From Camltac Require Import Camltac.` to the top of your Rocq files, and you're ready to go!

## Quickstart

Here's how you define a simple procedure (implemented [here](./examples/StdppMapReification.v)) reifying operations on [Std++'s `gmap`](https://gitlab.mpi-sws.org/iris/stdpp/-/blob/master/stdpp/gmap.v) in Camltac, and use it from Ltac2:

```coq
From Camltac Require Import Camltac.
From Ltac2 Require Import Ltac2.
From stdpp Require Import gmap.

Inductive map {K V : Type} :=
| MapEmpty
| MapInsert (k : K) (v : V) (m : map)
| MapUnion (m1 m2 : map).

Camltac Run ocaml:{{
  let rec reify x : constr tac =
    match%constr x with
    | "empty" -> {%open_constr| MapEmpty |}
    | "insert ?k ?v ?m" -> 
      let* m' = reify m in 
      {%constr| MapInsert %{k} %{v} %{m'} |}
    | "union ?m1 ?m2" ->
      let* m1' = reify m1 in
      let* m2' = reify m2 in
      {%constr| MapUnion %{m1'} %{m2'} |}

  (* Now, we expose it to Ltac2 as follows: *)
  let _ = Ltac2.FFI.(define "reify" (constr @-> tac constr) reify)
}}.

(* … and we can immediately use it! *)
Ltac2 @external reify : constr -> constr := "camltac.plugin.runtime" "reify".

Ltac2 Eval (reify constr:(insert 0 "Hello" (insert 1 "World" empty) : gmap nat string). 
(* = constr:(MapInsert 0 "Hello" (MapInsert 1 "World" MapEmpty)) *)
```

