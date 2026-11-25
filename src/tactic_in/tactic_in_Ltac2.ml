(** Support for OCaml tactics in Ltac2. *)

open Camltac_workspace
open Camltac_driver
open Ltac2_plugin
open Tac2expr

open Driver

(** {1 OCaml tactics in Ltac2} *)

(** Generic tag for OCaml snippets in Ltac2. *)
let wit_ocaml_in_ltac2: (Tactic.raw, Tactic.glob) Tac2dyn.Arg.tag =
  Tac2dyn.Arg.create "ocaml-in-ltac2"

let from_ocaml snippet =
  let loc = Snippet.loc snippet in
  let raw = Driver.Tactic.embed snippet in
  CAst.make ~loc (CTacExt (wit_ocaml_in_ltac2, raw))

(** {2 Internalization} *)

[%%if rocq >= (9, 2)]
let t_unit = Tac2quote.Refs.t_unit
let v_unit = Tac2quote.Refs.v_unit
[%%else]
let t_unit = Tac2core.Core.t_unit
let v_unit = Tac2core.Core.v_unit
[%%endif]

let intern glob_sign raw =
  let glob = Driver.Tactic.globalize glob_sign raw in
  Tac2env.GlbVal glob, GTypRef (Other t_unit, [])

(** {2 Interpretation} *)

let interp _ltac2_env tactic =
  let open Proofview.Monad in
  Driver.Tactic.interp tactic >> return v_unit

(** {2 Printing} *)

let () =
  let ml_object = Tac2env.{
    ml_intern    = intern;
    ml_subst     = Driver.Tactic.mod_subst;
    ml_interp    = interp;
    ml_raw_print = Driver.Tactic.print_raw;
    ml_print     = Driver.Tactic.print_glob;
  }
  in
  Tac2env.define_ml_object wit_ocaml_in_ltac2 ml_object
