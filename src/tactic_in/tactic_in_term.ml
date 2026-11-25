(** Support for tactic-in-terms using Rocq's generic argument mecanism. *)

open Camltac_workspace
open Camltac_driver
open Driver
open Names

(** {1 Tactic-in-terms} *)

(** In Rocq's implementation, a generic argument ([Genarg]) represents part of the
    syntax whose interpretation is given by a custom interpretation function.
    Schematically, such arguments use the following path:

    {v

             Internalization                        Interpretation
    Raw  ───────────────────────→ Globalized ───────────────────────→ Toplevel 
                                    │     ￪
                                    └─────┘
                                  Substitution

    v}

    For our purposes, we can treat OCaml quotations as generic arguments, which gives
    us access to the local env when interpreting.

    For a generic argument to properly be integrated, we need to register a few things:

    - [GenConstr.create]: create the tag of the generic argument.
    - [Genintern.register_intern_constr]: internalization function that converts from the raw representation
      to the globalized one, where names are resolved.
    - [Gensubst.register_constr_subst]: function used for module substitution (e.g. definition in module types).
    - [Genintern.register_ntn_subst0]: substitution of notation arguments.
    - [GlobEnv.register_constr_interp0]: interpretation function.
    - [Genprint.register_constr_print]: printing functions.
 *)

[%%if rocq >= (9, 3)]

let wit_ocaml_in_term : (Tactic.raw, Tactic.glob) GenConstr.tag =
  GenConstr.create "ocaml-in-term"

let make ?loc raw =
  CAst.make ?loc (Constrexpr.CGenarg (Raw (wit_ocaml_in_term, raw)))

[%%else]

let wit_ocaml_in_term : (Tactic.raw, Tactic.glob, Util.Empty.t) Genarg.genarg_type =
  Genarg.make0 "ocaml-in-term"

let make ?loc raw =
  CAst.make ?loc (Constrexpr.CGenarg (Genarg.GenArg (Rawwit wit_ocaml_in_term, raw)))

[%%endif]

let from_ocaml snippet =
  let raw = Driver.Tactic.embed snippet in
  make ~loc:(Snippet.loc snippet) raw

(** {2 Internalization} *)

let intern ?loc:_ = Driver.Tactic.globalize

[%%if rocq >= (9, 3)]
let () = Genintern.register_intern_constr wit_ocaml_in_term intern
[%%else]
let () =
  let intern ?loc glb_sign snippet = glb_sign, intern ?loc glb_sign snippet in
  Genintern.register_intern0 wit_ocaml_in_term intern
[%%endif]

(** {2 Module substitution} *)

[%%if rocq >= (9, 3)]
let () = Gensubst.register_constr_subst wit_ocaml_in_term Driver.Tactic.mod_subst
[%%else]
let () = Gensubst.register_subst0 wit_ocaml_in_term Driver.Tactic.mod_subst
[%%endif]

(** {2 Notation substitution} *)

let subst_notation _ map glob = Driver.Tactic.subst_notation_vars map glob

[%%if rocq >= (9, 1)]
let () = Genintern.register_ntn_subst0 wit_ocaml_in_term subst_notation
[%%else]
let () =
  let subst_notation vars map glob =
    let map = fun x -> Id.Map.find_opt x map in
    subst_notation vars map glob
  in
  Genintern.register_ntn_subst0 wit_ocaml_in_term subst_notation
[%%endif]

(** {2 Interpretation} *)

[%%if rocq >= (9, 2)]
let refine_by_tactic = Subproof.refine_by_tactic
[%%else]
let refine_by_tactic = Proof.refine_by_tactic
[%%endif]

let () =
  let interp ?loc:_ ~poly genv sigma tycon tactic =
    let tac: unit Proofview.tactic = Driver.Tactic.interp tactic in
    let name = Names.Id.of_string "camltac" in
    let sigma, concl = match tycon with
      | Some ty -> sigma, ty
      | None    -> GlobEnv.new_type_evar genv sigma ~src:(None, Evar_kinds.InternalHole)
    in
    let c, sigma = refine_by_tactic ~name ~poly (GlobEnv.renamed_env genv) sigma concl tac in
    let j = { Environ.uj_val = c; Environ.uj_type = concl } in
    (j, sigma)
  in
  GlobEnv.register_constr_interp0 wit_ocaml_in_term interp

(** {2 Printing} *)

open Genprint

let raw_printer raw =
  PrinterBasic (fun env sigma -> Driver.Tactic.print_raw env sigma raw)

let glob_printer glob =
  PrinterBasic (fun env sigma -> Driver.Tactic.print_glob env sigma glob)

[%%if rocq <= (9, 2)]
let () = Genprint.register_noval_print0 wit_ocaml_in_term raw_printer glob_printer
[%%else]
let () = Genprint.register_constr_print wit_ocaml_in_term raw_printer glob_printer
[%%endif]
