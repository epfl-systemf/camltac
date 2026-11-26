(** Support for OCaml tactics in Ltac. *)

open Ltac_plugin
open Driver

(** {1 Tactics in Ltac} *)

[%%if rocq >= (9, 3)]
let wit_ocaml_in_ltac : (Tactic.raw, Tactic.glob, Geninterp.Val.t) Genarg.genarg_type =
  let genarg = Genarg.make0 "ocaml-in-ltac" in
  Geninterp.register_val0 genarg (Some Any);
  genarg
[%%else]
let wit_ocaml_in_ltac : (Tactic.raw, Tactic.glob, Util.Empty.t) Genarg.genarg_type =
  Genarg.make0 "ocaml-in-ltac"
[%%endif]

let from_ocaml snippet =
  let artifact = Driver.Tactic.embed snippet in
  Tacexpr.TacGeneric (Some "ocaml", Genarg.(in_gen (rawwit wit_ocaml_in_ltac) artifact))

(** {2 Internalization} *)

let () =
  let intern glob_sign x = glob_sign, Driver.Tactic.globalize glob_sign x in
  Genintern.register_intern0 wit_ocaml_in_ltac intern

(** {2 Substitution} *)

let () = Gensubst.register_subst0 wit_ocaml_in_ltac Driver.Tactic.mod_subst

(** {2 Interpretation} *)

let idtac ist =
  Tacinterp.Value.of_closure
    { ist with lfun = Names.Id.Map.empty }
    (CAst.make (Tacexpr.TacId []))

let interp ist tactic =
  let open Proofview.Monad in
  Driver.Tactic.interp tactic >>= fun () ->
  Ftactic.return (idtac ist)

[%%if rocq >= (9, 3)]
let () = Tacinterp.Register.register_interp0 wit_ocaml_in_ltac interp
[%%else]
let () = Geninterp.register_interp0 wit_ocaml_in_ltac interp
[%%endif]

(** {2 Printing} *)

let raw_printer raw =
  Genprint.PrinterBasic (fun env sigma -> Driver.Tactic.print_raw env sigma raw)

let glob_printer glob =
  Genprint.PrinterBasic (fun env sigma -> Driver.Tactic.print_glob env sigma glob)

[%%if rocq >= (9, 3)]
let () =
  Genprint.register_print0
    wit_ocaml_in_ltac
    raw_printer
    glob_printer
    Genprint.generic_val_print
[%%else]
let () =
  Genprint.register_noval_print0
    wit_ocaml_in_ltac
    raw_printer
    glob_printer
[%%endif]
