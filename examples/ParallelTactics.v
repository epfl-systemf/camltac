(*|
================
Parallel tactics
================

This small example shows one can use Eio to launch tactics in parallel:
|*)

From Camltac Require Import Camltac.
From Ltac2 Require Import Ltac2.

Camltac Run ocaml:{{
   [@@@using "eio", "eio_main"]

   open Eio

   let parallel tacs =
     Eio_main.run (fun _env -> Fiber.any tacs)

   let _ = FFI.(define "parallel" (list (thunk valexpr) @-> tac valexpr) parallel)
}}.

Ltac2 @external parallel : (unit -> 'a) list -> 'a := "camltac.plugin.runtime" "parallel".

(*|
Now, let's apply it in a real setting. We demonstrate its effects on a simple reflection procedure versus `repeat constructor`.
|*)

Inductive even : nat -> Prop :=
  | ZeroEven : even 0
  | SSEven : forall n, even n -> even (S (S n)).

Fixpoint is_even (n : nat) : bool :=
  match n with
    | 0 => true
    | S n => negb (is_even n)
  end.

Axiom is_even_soundness : forall n, is_even n = true -> even n.

Goal even 5000.
  Time let proof := parallel [
    (fun () => constr:(ltac:(refine (_ : even 5000); apply is_even_soundness; vm_compute; reflexivity)));
    (fun () => constr:(ltac:(refine (_ : even 5000); repeat constructor)))
  ] in exact $proof.
Qed.
