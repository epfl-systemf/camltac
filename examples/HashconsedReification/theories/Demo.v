(*|
======================
Hashconsed reification
======================

This plugin demonstrates how one can perform reification with hash-consing, which is currently not possible with Ltac2, and painful with an OCaml plugin.
|*)

From Ltac2 Require Import Ltac2.
From HashconsedReification Require Import Loader IdentParsing.

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
        constr:(Literal $a')
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
  Goal True.
  Proof.
    pose (large_term := exp 18).
    unfold exp in large_term.

    (* Without hashconsing: *)
    Time Ltac2 Eval (
        let t := eval unfold &large_term in &large_term in
          let _ := ml_reify t in ()).

    (* With hashconsing: *)
    Time Ltac2 Eval (
        let t := eval unfold &large_term in &large_term in
          let _ := hashcons_reify t in ()).

(*|
Completely instant!

.. coq:: none
|*)

  Abort.
End MLReification.

(*|

Notes
=====

What we wish for is roughly the following embed OCaml tactic:

.. Note: perhaps an injection mechanism from OCaml data type to Rocq?

.. code:: ocaml

   let make cons ?args =
     (* Hashconsing... *)

   let rec reify t =
     match t with
     | {%pat|true|} => make "Literal" [%constr true]
     | {%pat|false|} => make "Literal" [%constr false]
     | {%pat|negb ?x|} => make "Neg" [| reify x |]
     | {%pat|andb ?x ?y|} => make "And" [| reify x; reify y |]
     | {%pat|orb ?x ?y|} => make "Or" [| reify x; reify y |]
|*)
