(*|
==============
Hint databases
==============

Currently, there's no API for accessing hint databases from Ltac2: there's an open PR for it (https://github.com/rocq-prover/rocq/pull/21604), but it won't land in Rocq until Rocq 9.3.

In the meantime, you can access them from OCaml, as Fiat does:
|*)

Require Import MLtac.MLtac.
Require Import Ltac2.Ltac2.

MLtac Run ocaml:{{
  open Tacticals
  open Ltac_plugin
  open Ltac2_plugin
  open Tac2ffi
  open Tac2externals

  let with_hint_db dbs tacK =
    (* [dbs] : list of hint databases *)
    (* [tacK] : tactic to run on a hint *)
    Proofview.Goal.enter begin
	fun gl ->
	let syms = ref [] in
	let _ =
	  List.iter (fun l ->
		     (* Fetch the searchtable from the database*)
		     let db = Hints.searchtable_map l in
		     (* iterate over the hint database, pulling the hint *)
		     (* list out for each. *)
		     Hints.Hint_db.iter (fun _ _ hintlist ->
					 syms := hintlist::!syms) db) dbs in
	(* Now iterate over the list of list of hints, *)
	List.fold_left
	  (fun tac hints ->
	   List.fold_left
	     (fun tac hint1 ->
	      Hints.FullHint.run hint1
		       (fun hint2 ->
			      (* match the type of the hint to pull out the lemma *)
			      match hint2 with
				Hints.Give_exact h
			      | Hints.Res_pf h
			      | Hints.ERes_pf h ->
                                 let _, lem = Hints.hint_as_term h in
				 tclORELSE (tacK lem) tac
			      | _ -> tac))
	     tac hints)
	  (tclFAIL (Pp.str "No applicable tactic!")) !syms
      end

  let add_resolve_to_db lem db =
    Proofview.Goal.enter begin fun gl ->
      let sigma = Proofview.Goal.sigma gl in
      (* Tolerate applications to please tclABSTRACT in a section *)
      let lem, _ = EConstr.decompose_app sigma lem in
      match EConstr.destRef sigma lem with
      | lem, _ ->
        let () = Hints.add_hints ~locality:Hints.Local db (Hints.HintsResolveEntry [({ Typeclasses.hint_priority = Some 1 ; Typeclasses.hint_pattern = None }, true, lem)]) in
        tclIDTAC
      | exception Constr.DestKO -> tclFAIL (Pp.str "Cannot add non-global to hint database")
    end

  let () = Runtime.Registry.register_ltac2 "add_resolve_to_db" (constr @-> list string @-> tac unit) add_resolve_to_db
  let () = Runtime.Registry.register_ltac2 "with_hint_db" (list string @-> fun1 constr unit @-> tac unit) with_hint_db
}}.

Ltac2 @external add_to_dbs : constr -> string list -> unit := "mltac.plugin.runtime" "add_resolve_to_db".
Ltac2 @external with_hint_db : string list -> (constr -> unit) -> unit := "mltac.plugin.runtime" "with_hint_db".

(*|
Demo:
|*)

Create HintDb foo.

Axiom dummy_lemma : 3 = 5.

Goal 3 = 5.
  add_to_dbs constr:(dummy_lemma) ["foo"].
  auto with foo.
Qed.
