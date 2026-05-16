# Camltac: OCaml as a Tactic Language

Camltac enables Rocq users to write OCaml tactics directly inside their Rocq files. It supports all constructs from Ltac2, including term construction (`constr:(…)`), pattern matching, antiquotations, and more. Moreover, Camltac ships with most of the [Ltac2 API](https://rocq-prover.org/doc/master/corelib/index.html#Ltac2), so that your knowledge of Ltac is not lost.

See the [quickstart](#quickstart) section for ready-to-use examples.

## Setup

To install Camltac, clone the repo and run `dune install`, as follows:

```sh
git clone git@github.com:epfl-systemf/camltac.git
cd camltac
dune build
dune install
```

Then, add `From Camltac Require Import Camltac.` to the top of your Rocq files, and you're ready to go!

## Quickstart

Here's how you define a simple reification procedure for natural numbers in Camltac, and use it in Ltac2:

```coq
From Camltac Require Import Camltac.
From Ltac2 Require Import Ltac2.

Inductive expr :=
| NatZero
| NatSucc (e : expr)
| NatMul (e1 e2 : expr).

Camltac Run ocaml:{{
  let rec reify t =
    match%constr t with
    | "0" -> [%constr "NatZero"]
    | "S ?n" -> let* n' = reify n in [%constr "NatSucc %{n'}"]
    | "Nat.mul ?x ?y" ->
      let* left = reify x in
      let* right = reify y in
      [%constr "NatMul %{left} %{right}"]

  (* Now, we expose it to Ltac2 as follows: *)
  let () = Ltac2.FFI.(define "reify" (constr @-> tac constr) reify)
}}.

(* … and we can immediately use it! *)
Ltac2 @external reify : constr -> constr := "camltac.plugin.runtime" "reify".

Ltac2 Eval (reify constr:(100 * 100 * 100 * 100 * 100)). (* constr:(NatMul (NatMul (…))) *)
```

