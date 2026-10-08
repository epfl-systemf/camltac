(*|
================
Parallel tactics
================

This small example shows one can use Eio to launch tactics in parallel:
|*)

From Camltac Require Import Camltac.
From Ltac2 Require Import Ltac2.

#[libraries(eio, eio_main)]
Camltac Run ocaml:{{
   open Eio

   (* Each tactic runs in its own domain on a copy of the current evar map; the
      first one to finish wins and its evar map is kept. *)
   let parallel tacs =
     let* env = Tactic.env in
     let* sigma = Tactic.sigma in
     let won = Atomic.make false in
     let run tac () =
       try
         let _, pv = Proofview.init sigma [] in
         let v, pv, _, _, _ =
           Proofview.apply ~name:{%ident| parallel |} ~poly:PolyFlags.default env (tac ()) pv in
         (* Domains cannot be cancelled: ask the other tactics to stop through
            Rocq's interrupt flag. *)
         if Atomic.compare_and_set won false true then Control.interrupt := true;
         Some (v, snd (Proofview.proofview pv))
       with _ when Atomic.get won -> None
     in
     let v, sigma = Eio_main.run (fun env ->
       let mgr = Stdenv.domain_mgr env in
       let run_tac tac () =
         match Domain_manager.run mgr (run tac) with
         | Some r -> r
         | None -> Fiber.await_cancel ()
       in
       Fiber.any (List.map run_tac tacs))
     in
     Control.interrupt := false;
     let* () = Proofview.Unsafe.tclEVARS sigma in
     return v

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

Definition N := 5000.

Goal even N.
Proof.
  Time let proof := parallel [
    (fun () => constr:(ltac:(refine (_ : even N); repeat constructor)));
    (fun () => constr:(ltac:(refine (_ : even N); apply is_even_soundness; cbv; reflexivity)))
  ] in exact $proof.

  Show Proof.

  (* Reodering the proofs yields the same results: *)
  Set Warnings "-undo-batch-mode".
  Undo.

  Time let proof := parallel [
    (fun () => constr:(ltac:(refine (_ : even N); apply is_even_soundness; cbv; reflexivity)));
    (fun () => constr:(ltac:(refine (_ : even N); repeat constructor)))
  ] in exact $proof.

  Show Proof.
Qed.
