(*|
======================
Hashconsed reification
======================

This plugin demonstrates how one can perform reification with hash-consing, which is currently not possible with Ltac2, and painful with an OCaml plugin.
|*)

From Camltac Require Import Camltac.
From Ltac2 Require Import Ltac2.
Require Import IdentParsing.

From Stdlib Require Import String Arith.

Inductive bool_expr : Type :=
| Literal (b : bool)
| Var (x : string)
| Neg (a : bool_expr)
| And (a b : bool_expr)
| Or (a b : bool_expr).

(*|
We want to reify Boolean expressions into [bool_expr].

For reference, here is the Ltac2 script that performs this reification:
|*)
Section Ltac2Reification.

  Ltac2 rec reify (t : constr) : constr :=
    lazy_match! t with
    | true => constr:(Literal true)
    | false => constr:(Literal false)
    | negb ?a =>
        let a' := reify a in
        constr:(Neg $a')
    | andb ?a ?b =>
        let a' := reify a in
        let b' := reify b in
        constr:(And $a' $b')
    | orb ?a ?b =>
        let a' := reify a in
        let b' := reify b in
        constr:(Or $a' $b')
    | _ =>
        match Constr.Unsafe.kind t with
        | Constr.Unsafe.Var v =>
            (* Rely on a hacky script for converting Ltac2 idents to Rocq strings *)
            let name := coq_string_of_ident v in constr:(Var $name)
        | _ => Control.zero Match_failure
        end
    end.

(*|
This reification will perform poorly when subterms are shared, as in the following formula:
|*)

  Fixpoint exp (n : nat) : bool :=
    match n with
    | 0 => true
    | S n' => andb (exp n') (exp n')
    end.

  Goal True.
  Proof.
    pose (large_term := exp 18).
    unfold exp in large_term.

    
    Time Ltac2 Eval (
        let t := eval unfold &large_term in &large_term in
          let _ := reify t in ()).
  Abort.
End Ltac2Reification.

(*|
Now, compare it to the hashconsed reification procedure:
|*)

Section MLReification.
  Camltac Run ocaml:{{
    let rec reify t =
      match%constr t with
      | "true" -> [%constr "Literal true"]
      | "false" -> [%constr "Literal false"]
      | "negb ?x" ->
         let* x = reify x in
         [%constr "Neg %{x}"]
      | "andb ?x ?y" ->
         let* left = reify x in
         let* right = reify y in
         [%constr "And %{left} %{right}"]
      | "orb ?x ?y" ->
         let* left = reify x in
         let* right = reify y in
         [%constr "Or %{left} %{right}"]
      | _ -> user_error (Pp.str "Unrecognized term.")

    let () = Ltac2.FFI.(define "reify" (constr @-> tac constr) reify)
  }}.

  Ltac2 @external ml_reify : constr -> constr := "camltac.plugin.runtime" "reify".

  Goal True.
  Proof.
    pose (large_term := exp 18).
    unfold exp in large_term.

    Time Ltac2 Eval (
        let t := eval unfold &large_term in &large_term in
          let _ := ml_reify t in ()).

(*|
Completely instant!

.. coq:: none
|*)

  Abort.
End MLReification.
