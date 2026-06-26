(*|
=======
Tracing
=======

This small example shows one can use `ppx_minidebug`, an OCaml preprocessor extension,
to add tracing capabilities to a tactic.
|*)

From Camltac Require Import Camltac.
From Ltac2 Require Import Ltac2.

Inductive my_nat :=
  | NatZero
  | NatSucc (n : my_nat)
  | NatMul (n m : my_nat).

Camltac Run ocaml:{{
  [@@@ppx "ppx_minidebug"]

  (* Initialize ppx_minidebug runtime. *)
  let _get_local_debug_runtime =
    let rt = Minidebug_db.debug_db_file "trace" in
    fun () -> rt

  let pp_constr fmt (c: constr) =
     let env = Global.env () in
     let sigma = Evd.from_env env in
     let s = Pp.string_of_ppcmds @@ Printer.pr_constr_env env sigma (EConstr.to_constr sigma c) in
     Format.pp_print_string fmt s

  type constr_tactic = constr Proofview.tactic
  let pp_constr_tactic fmt (_t: constr_tactic) =
     Format.pp_print_string fmt "<tactic>"

  (* Let us implement a simple recursive procedure, with tracing enabled! *)
  let%debug_pp rec reify (x : constr) : constr_tactic =
    match%constr x with
    | "0" -> [%constr "NatZero"]
    | "S ?n" ->
      let* n' = reify n in
      [%constr "NatSucc %{n'}"]
    | "?n * ?m" ->
      let* n' = reify n in
      let* m' = reify m in
      [%constr "NatMul %{n'} %{m'}"]

  let _ = FFI.(define "reify" (constr @-> tac constr) reify)

}}.

Ltac2 @external reify : constr -> constr := "camltac.plugin.runtime" "reify".

(* Calling our recursive procedure triggers the tracing: *)
Ltac2 Eval (reify constr:(1 * 2 * 3)).

(* which we can visualize using [minidebug_view trace.db tui]! *)
