(*|
==============
Hint databases
==============

Currently, there's no API for accessing hint databases from Ltac2: there's an open PR for it (https://github.com/rocq-prover/rocq/pull/21604), but it won't land in Rocq until Rocq 9.3.

In the meantime, you can access them from OCaml, as Fiat does:
|*)

Require Import Camltac.Camltac.
Require Import Ltac2.Ltac2.

(* Code simplified from Fiat's HintDb plugin: https://github.com/mit-plv/fiat/blob/master/src/Common/Tactics/hint_db_extra_tactics.ml.v92 *)
Camltac Run ocaml:{{
  let with_hint_db dbs tacK =
    let dbs = List.map HintDb.get_db dbs in
    (* [dbs] : list of hint databases *)
    (* [tacK] : tactic to run on a hint *)
    Proofview.Goal.enter begin fun gl ->
      let hints = List.concat_map HintDb.all_hints dbs in
      let tac = fail (Pp.str "No applicable tactic!") in
      List.fold_left begin fun tac hint ->
        HintDb.Hint.run hint begin fun hint_ast ->
          match hint_ast with
            Exact h
          | Apply h
          | EApply h ->
             let _, lem = Hints.hint_as_term h in
             let open Syntax in
             (tacK lem) || tac
          | _ -> tac
          end
        end tac hints
      end

  let add_resolve_to_db lem db =
    let db = HintDb.get_db db in
    Proofview.Goal.enter begin fun gl ->
      let sigma = Proofview.Goal.sigma gl in
      (* Tolerate applications to please tclABSTRACT in a section *)
      let lem, _ = EConstr.decompose_app sigma lem in
      match EConstr.destRef sigma lem with
      | lem, _ ->
         let _ = HintDb.hint_resolve ~cost:1 lem db in
         return ()
      | exception Constr.DestKO -> fail (Pp.str "Cannot add non-global to hint database")
      end

  let () = Ltac2.FFI.(define "add_resolve_to_db" (constr @-> string @-> tac unit) add_resolve_to_db)
  let () = Ltac2.FFI.(define "with_hint_db" (list string @-> fun1 constr unit @-> tac unit) with_hint_db)
}}.

Ltac2 @external add_to_db : constr -> string -> unit := "camltac.plugin.runtime" "add_resolve_to_db".
Ltac2 @external with_hint_db : string list -> (constr -> unit) -> unit := "camltac.plugin.runtime" "with_hint_db".

(*|
Demo:
|*)

Create HintDb foo.

Axiom dummy_lemma : 3 = 5.

Goal 3 = 5.
  add_to_db constr:(dummy_lemma) "foo".
  auto with foo.
Qed.
