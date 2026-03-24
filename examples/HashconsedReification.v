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

    let plugin_name = "mltac.plugin.runtime"
    let pname s = { Tac2expr.mltac_plugin = plugin_name; mltac_tactic = s }
    
    let define s = define (pname s)
    
    let ref_to_constr ref =
      EConstr.of_constr (UnivGen.constr_of_monomorphic_global (Global.env ()) ref)
    let constr_of_qualid n =
      let qualid = Libnames.qualid_of_string n in
      lazy (let ref = Nametab.locate qualid in ref_to_constr ref)
    
    let bool_typ = constr_of_qualid "bool"
    let trueb    = constr_of_qualid "true"
    let falseb   = constr_of_qualid "false"
    let andb     = constr_of_qualid "andb"
    let orb      = constr_of_qualid "orb"
    let negb     = constr_of_qualid "negb"
    
    let bool_expr = constr_of_qualid "bool_expr"
    let bool_expr_Literal = constr_of_qualid "Literal"
    let bool_expr_Var = constr_of_qualid "Var"
    let bool_expr_Neg = constr_of_qualid "Neg"
    let bool_expr_And = constr_of_qualid "And"
    let bool_expr_Or = constr_of_qualid "Or"
    
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
    
    let rec quote factories evd t =
      match EConstr.kind evd t with
      | Construct _ -> factories.literal_cons (EConstr.eq_constr evd t @@ Lazy.force trueb)
      | App (head, args) when head = Lazy.force negb && Array.length args = 1 ->
         let arg = quote factories evd args.(0) in
         factories.neg_cons arg
      | App (head, args) when Array.length args = 2 ->
         let left = quote factories evd args.(0) in
         let right = quote factories evd args.(1) in
         let op =
           if head = Lazy.force andb then factories.and_cons
           else if head = Lazy.force orb then factories.or_cons
           else failwith "Unknown boolean function."
         in op left right
      | Var ident ->
         failwith "Variables aren't supported, because I don't want to convert OCaml strings to Rocq strings by hand :("
      | _ -> CErrors.user_err (Pp.str "Unrecognized term.")
    
    let rec unquote e =
      let make cons args =
        let cons = Lazy.force cons in
        EConstr.mkApp (cons, args)
      in
      match e with
      | Literal true -> make bool_expr_Literal [| Lazy.force trueb |]
      | Literal false -> make bool_expr_Literal [| Lazy.force falseb |]
      | Neg e' -> make bool_expr_Neg [| unquote e' |]
      | And (e1, e2) -> make bool_expr_And [| unquote e1; unquote e2 |]
      | Or (e1, e2) -> make bool_expr_Or [| unquote e1; unquote e2 |]
    
    (* Our reification function is parametrized by how we construct new applied terms.
       For simple reification, taking [factories = default_factories] works.
       If we want hashconsing, we must use a memoizing variant. *)
    let reify factories t =
      let env = Global.env () in
      let evd = Evd.from_env env in
      let t = Termops.strip_head_cast evd t in
      unquote (quote factories evd t)
    
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
    
    let () = define "reify" (constr @-> ret constr) @@ (reify default_factories)
    let () = define "hashcons_reify" (constr @-> ret constr) @@ (reify memoized_factories)
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

(*|

Notes
=====

What we wish for is roughly the following embed OCaml tactic:

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



