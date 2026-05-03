(*|
======================
Hashconsed reification
======================

This plugin demonstrates how one can perform reification with hash-consing, which is currently not possible with Ltac2, and painful with an OCaml plugin.
|*)

From MLtac Require Import MLtac.
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
  MLtac Run ocaml:{{
    open Ltac2_plugin
    open Tac2externals
    open Tac2ffi

    (* Let us define our own data type in OCaml, and convert it from/to constr when necessary. *)
    type bool_expr =
      | Literal of bool
      | Neg of bool_expr
      | And of bool_expr * bool_expr
      | Or of bool_expr * bool_expr
    
    type constructors = {
      literal_cons: bool -> bool_expr;
      neg_cons: bool_expr -> bool_expr;
      and_cons: bool_expr -> bool_expr -> bool_expr;
      or_cons: bool_expr -> bool_expr -> bool_expr;
    }
    
    let rec quote factories t =
      match%pat t with
      | "true" -> return (factories.literal_cons true)
      | "false" -> return (factories.literal_cons false)
      | "negb ?x" ->
         let* x = quote factories x in
         return (factories.neg_cons x)
      | "andb ?x ?y" ->
         let* left = quote factories x in
         let* right = quote factories y in
         return (factories.and_cons left right)
      | "orb ?x ?y" ->
         let* left = quote factories x in
         let* right = quote factories y in
         return (factories.or_cons left right)
      | _ -> user_error (Pp.str "Unrecognized term.")
    
    let rec unquote e =
      match e with
      | Literal true -> [%constr "Literal true"]
      | Literal false -> [%constr "Literal false"]
      | Neg e' ->
        let* e' = unquote e' in [%constr "Neg %{e'}"]
      | And (e1, e2) ->
        let* e1 = unquote e1 in
        let* e2 = unquote e2 in
        [%constr "And %{e1} %{e2}"]
      | Or (e1, e2) ->
        let* e1 = unquote e1 in
        let* e2 = unquote e2 in
        [%constr "Or %{e1} %{e2}"]

    (* Our reification function is parametrized by how we construct new applied terms.
       For simple reification, taking [factories = default_factories] works.
       If we want hashconsing, we must use a memoizing variant. *)
    let reify factories t =
      let* quoted = quote factories t in
      unquote quoted
    
    let default_factories = {
        literal_cons = (fun b -> Literal b);
        neg_cons = (fun a -> Neg a);
        and_cons = (fun a b -> And (a, b));
        or_cons = (fun a b -> Or (a, b));
    }
    
    let cache: (bool_expr, bool_expr) Hashtbl.t = Hashtbl.create 97
    let memoized_factories =
      let get_cached value =
        try Hashtbl.find cache value
        with Not_found -> Hashtbl.add cache value value; value
      in {
        literal_cons = (fun b -> get_cached (Literal b));
        neg_cons = (fun a -> get_cached (Neg a));
        and_cons = (fun a b -> get_cached (And (a, b)));
        or_cons = (fun a b -> get_cached (Or (a, b)));
      }
    
    let () = Runtime.Registry.register_ltac2 "reify" (constr @-> tac constr) @@ (reify default_factories)
    let () = Runtime.Registry.register_ltac2 "hashcons_reify" (constr @-> tac constr) @@ (reify memoized_factories)
  }}.

  (** A function that reifies the given boolean term using OCaml. *)
  Ltac2 @external ml_reify : constr -> constr := "mltac.plugin.runtime" "reify".
  
  (** A function that reifies and hashconses the given boolean term using OCaml. *)
  Ltac2 @external hashcons_reify : constr -> constr := "mltac.plugin.runtime" "hashcons_reify".
  
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
