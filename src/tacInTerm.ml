(** Support for tactic-in-terms using Rocq's generic argument mecanism. *)

open Names

(** {1 OCaml-in-terms} *)

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

(** Raw representation of OCaml snippets. *)
type raw_ocaml = Snippet.t

(** Globalized representation of OCaml snippets. *)
type glob_ocaml =
  { env: Runtime.Environment.t;
    snippet: raw_ocaml }

let wit_ocaml_in_term : (raw_ocaml, glob_ocaml) GenConstr.tag = GenConstr.create "ocaml"

(** {2 Internalization} *)

let intern ?loc glb_sign snippet =
  { env = Runtime.Environment.capture glb_sign; snippet }

let () = Genintern.register_intern_constr wit_ocaml_in_term intern

(** Substitution (globalized -> globalized)
    Used for module substitutions (e.g. definitions in module types) *)

let subst s { env; snippet } =
  { env = Runtime.Environment.map (Detyping.subst_glob_constr (Global.env()) s) env;
    snippet }

let () = Gensubst.register_constr_subst wit_ocaml_in_term subst

(** Notation substitution (globalized -> globalized) *)

let subst_notation notation_vars map { env; snippet } =
  { env = Runtime.Environment.map_unresolved map env;
    snippet }

let () = Genintern.register_ntn_subst0 wit_ocaml_in_term subst_notation

(** Interpretation of OCaml-in-terms *)
let interp ?loc ~poly genv sigma tycon { env; snippet } =
  (* Create the scaffold *)
  let scaffold = Scaffold.make snippet in
  let variables = Runtime.Environment.variables env in
  let scaffold = Id.Set.fold (fun var scaffold ->
                     let var = Id.to_string var in
                     let binding = Format.sprintf {|let %s = Runtime.Environment.lookup (Names.Id.of_string "%s") in|} var var in
                     Scaffold.wrap ~before:binding ~after:"" scaffold) variables scaffold in
  let scaffold = Scaffold.wrap ~before:"Runtime.Registry.register_output begin" ~after:"end" scaffold in
  (* Run the code *)
  let () = Runner.run_code ~env (Scaffold.contents scaffold) in
  (* Interpret the result as a tactic *)
  let tac: 'a Proofview.tactic = Runtime.Registry.get_last_output () in
  let tac = Proofview.tclIGNORE tac in
  let name = Names.Id.of_string "mltac" in
  let sigma, concl = match tycon with
    | Some ty -> sigma, ty
    | None -> GlobEnv.new_type_evar genv sigma ~src:(Some (Snippet.loc snippet), Evar_kinds.InternalHole)
  in
  let c, sigma = Subproof.refine_by_tactic ~name ~poly (GlobEnv.renamed_env genv) sigma concl tac in
  let j = { Environ.uj_val = c; Environ.uj_type = concl } in
  (j, sigma)

let () = GlobEnv.register_constr_interp0 wit_ocaml_in_term interp


(** Printing OCaml-in-terms quotations *)

open Genprint

let ocaml_printer snippet =
  PrinterBasic begin fun _env _evd ->
    Pp.str (Snippet.contents snippet)
  end

let glob_ocaml_printer { env; snippet } =
  let open Pp in
  PrinterBasic begin fun _env _evd ->
    let vars = Runtime.Environment.variables env in
    let vars = Id.Set.fold List.cons vars [] in
    match vars with
    | [] -> str (Snippet.contents snippet)
    | _ ->
       (* TODO: This representation is not valid syntax *)
       pr_sequence Id.print vars ++ str " |-" ++ str (Snippet.contents snippet)
  end

let () = 
  Genprint.register_constr_print wit_ocaml_in_term ocaml_printer glob_ocaml_printer
