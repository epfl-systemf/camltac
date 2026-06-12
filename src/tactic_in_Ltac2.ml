(** Support for OCaml tactics in Ltac2. *)

open Names
open Ltac2_plugin
open Tac2expr

type t = Snippet.t * Compiler.output

(** Generic tag for OCaml snippets in Ltac2. *)
let wit_ocaml_in_ltac2: (t, t) Tac2dyn.Arg.tag = Tac2dyn.Arg.create "ocaml-in-ltac2"

let from_ocaml snippet =
  let loc = Snippet.loc snippet in
  let compilation_output = Main.compile_snippet Snippet.Tactic_in_Ltac2 snippet in
  CAst.make ~loc (CTacExt (wit_ocaml_in_ltac2, (snippet, compilation_output)))

let camltac_ltac2_prefix =
  MPfile (DirPath.make (List.map Id.of_string ["Ltac2"; "Camltac"]))

let camltac_ocaml_ltac2_type =
  KerName.make camltac_ltac2_prefix (Id.of_string "ocaml")

let intern glob_sign x =
  (* TODO: Do something with [glob_sign]. Most likely we would need to
           internalize every constr in the snippet with [glob_sign]? *)
  Tac2env.GlbVal x, GTypRef (Other Tac2quote.Refs.t_unit, [])

let subst _ x = x

let interp ltac2_env (_, compilation_output) =
  (* Run the code *)
  let () = Main.interpret Snippet.Tactic_in_Ltac2 compilation_output in
  (* Interpret the result as a tactic *)
  let open Proofview.Monad in
  Runtime.Output.get_tactic () >> return Tac2quote.Refs.v_unit

(** {2 Printing} *)

let print _env _sigma (snippet, _) =
  Pp.str (Snippet.contents snippet)

let raw_print = print

let () =
  let ml_object = Tac2env.{
    ml_intern = intern;
    ml_subst = subst;
    ml_interp = interp;
    ml_raw_print = raw_print;
    ml_print = print;
  }
  in
  Tac2env.define_ml_object wit_ocaml_in_ltac2 ml_object
