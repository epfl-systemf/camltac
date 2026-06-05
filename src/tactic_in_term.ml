(** Support for tactic-in-terms using Rocq's generic argument mecanism. *)

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

(** Representation of OCaml snippets in [Constrexpr.constr_expr] terms.

    Note that snippets are compiled once at parsing time, so that the compilation
    overhead is amortized over each interpretation. *)
type raw_ocaml = {
    source_code: Snippet.t;              (** Source code of the snippet. *)
    compilation_output: Compiler.output; (** Compilation output. *)
}

(** Representation of OCaml snippets in [Glob_term.glob_constr] terms. *)
type glob_ocaml = raw_ocaml * Runtime.Environment.t

let wit_ocaml_in_term : (raw_ocaml, glob_ocaml) GenConstr.tag = GenConstr.create "ocaml"

let from_ocaml snippet =
  let compilation_output = Main.compile_snippet Snippet.Tactic_in_term snippet in
  let raw = { source_code = snippet; compilation_output } in
  CAst.make ~loc:(Snippet.loc snippet) @@ Constrexpr.(CGenarg (Raw (wit_ocaml_in_term, raw)))

(** {2 Internalization} *)

let () =
  let intern ?loc glb_sign snippet =
    snippet, Runtime.Environment.capture glb_sign
  in
  Genintern.register_intern_constr wit_ocaml_in_term intern

(** {2 Module substitution} *)

let () =
  let subst s (snippet, env) =
    snippet, Runtime.Environment.map (Detyping.subst_glob_constr (Global.env()) s) env
  in
  Gensubst.register_constr_subst wit_ocaml_in_term subst

(** {2 Notation substitution} *)

let () =
  let subst_notation notation_vars map (snippet, env) =
    snippet, Runtime.Environment.map_unresolved map env
  in
  Genintern.register_ntn_subst0 wit_ocaml_in_term subst_notation

(** {2 Interpretation} *)

let () =
  let interp ?loc ~poly genv sigma tycon ({ source_code; compilation_output }, env) =
    (* Run the code *)
    let () = Main.interpret Snippet.Tactic_in_term compilation_output in
    (* Interpret the result as a tactic *)
    let tac: unit Proofview.tactic = Runtime.Output.get_tactic () in
    let name = Names.Id.of_string "camltac" in
    let sigma, concl = match tycon with
      | Some ty -> sigma, ty
      | None -> GlobEnv.new_type_evar genv sigma ~src:(Some (Snippet.loc source_code), Evar_kinds.InternalHole)
    in
    let () = Runtime.Environment.set_env env in
    let c, sigma = Subproof.refine_by_tactic ~name ~poly (GlobEnv.renamed_env genv) sigma concl tac in
    let () = Runtime.Environment.unset_env () in
    let j = { Environ.uj_val = c; Environ.uj_type = concl } in
    (j, sigma)
  in
  GlobEnv.register_constr_interp0 wit_ocaml_in_term interp

(** {2 Printing} *)

open Genprint

let () =
  let ocaml_printer { source_code } =
    PrinterBasic begin fun _env _evd ->
      Pp.str (Snippet.contents source_code)
      end
  in
  let glob_ocaml_printer ({ source_code }, env) =
    let open Pp in
    PrinterBasic begin fun _env _evd ->
      let vars = Runtime.Environment.variables env in
      let vars = Id.Set.fold List.cons vars [] in
      match vars with
      | [] -> str (Snippet.contents source_code)
      | _ ->
         (* TODO: This representation is not valid syntax *)
         pr_sequence Id.print vars ++ str " |-" ++ str (Snippet.contents source_code)
      end
  in
  Genprint.register_constr_print wit_ocaml_in_term ocaml_printer glob_ocaml_printer
