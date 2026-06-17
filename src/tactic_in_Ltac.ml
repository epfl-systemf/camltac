(** Support for OCaml tactics in Ltac. *)

open Ltac_plugin

(** {1 Tactics in Ltac} *)

type t = Snippet.t * Compiler.output

let wit_ocaml_in_ltac : (t, t, Geninterp.Val.t) Genarg.genarg_type =
  Genarg.make0 "ocaml-in-ltac"

let from_ocaml snippet =
  let compilation_output = Main.compile_snippet Snippet.Tactic_in_Ltac snippet in
  Tacexpr.TacGeneric (Some "ocaml", Genarg.(in_gen (rawwit wit_ocaml_in_ltac) (snippet, compilation_output)))

(** {2 Internalization} *)

let () =
  let intern glob_sign x = glob_sign, x in
  Genintern.register_intern0 wit_ocaml_in_ltac intern

(** {2 Substitution} *)

let () =
  let subst _ x = x in
  Gensubst.register_subst0 wit_ocaml_in_ltac subst

(** {2 Interpretation} *)

let () = Geninterp.register_val0 wit_ocaml_in_ltac (Some Any)

let () =
  let interp ist (_, compilation_output) =
    let Compiler.{ compiled_file; dependencies } = compilation_output in
    Loader.load_file ~public:false ~dependencies compiled_file;
    let idtac = Tacinterp.Value.of_closure { ist with lfun = Names.Id.Map.empty } (CAst.make (Tacexpr.TacId [])) in
    (* Get the resulting tactic. *)
    let tactic: unit Proofview.tactic = Runtime.Output.get_tactic () in
    let open Proofview.Monad in
    tactic >>= fun () ->
    Ftactic.return idtac
  in
  Tacinterp.Register.register_interp0 wit_ocaml_in_ltac interp

(** {2 Printing} *)
let () =
  let printer (snippet, _) =
    Genprint.PrinterBasic (fun _env _evd -> Pp.str (Snippet.contents snippet))
  in
  Genprint.register_print0 wit_ocaml_in_ltac printer printer Genprint.generic_val_print
