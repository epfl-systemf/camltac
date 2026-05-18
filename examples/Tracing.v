(*|
=======
Tracing
=======

This small example shows one can use `ppx_minidebug`, an OCaml preprocessor extension,
to add tracing capabilities to a tactic.
|*)

From Camltac Require Import Camltac.

Inductive my_nat :=
  | NatZero
  | NatSucc (n : my_nat)
  | NatMul (n m : my_nat).

(* FIXME: ppx_minidebug leads to linking errors. *)
(*
Camltac Run ocaml:{{
  [@@@using "ppx_minidebug.runtime"]
  [@@@ppx "ppx_minidebug"]

  (* Let us implement a simple recursive procedure, with tracing enabled! *)
  let%debug_pp rec reify x =
    match%constr x with
    | "0" -> [%constr "NatZero"]
    | "S ?n" ->
      let* n' = reify n in
      [%constr "NatSucc %{n'}"]
    | "?n * ?m" ->
      let* n' = reify n in
      let* m' = reify m in
      [%constr "NatMul %{n'} %{m'}"]

  let _ = Ltac2.FFI.(define "reify" (constr @-> tac constr) reify)
}}.

Ltac2 @external reify : constr -> constr := "camltac.plugin.runtime" "reify".

(* Calling our recursive procedure prints each recursive argument: *)
Ltac2 Eval (reify constr:(1 * 2 * 3)).

*)
