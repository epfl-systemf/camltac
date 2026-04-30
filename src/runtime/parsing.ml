(** API for parsing terms. *)

open Names
open Api.Tactics

let parse entry s = Procq.parse_string entry s

let parse_constrexpr = parse Procq.Constr.term
let parse_ident      = parse Procq.Constr.ident
let parse_qualid     = parse Procq.Prim.qualid
let parse_pattern    = parse Procq.Constr.cpattern
let parse_vernac     = parse Pvernac.Vernac_.vernac_control
let parse_ltac       = parse Ltac_plugin.Pltac.tactic
let parse_ltac2      = parse Ltac2_plugin.G_ltac2.ltac2_expr

let glob_constr_of_string s =
  let parsed_term = parse_constrexpr s in
  with_env begin fun env sigma ->
    return (Constrintern.intern_constr env sigma parsed_term)
  end

let constr_of_string s =
  let parsed_term = parse_constrexpr s in
  with_env begin fun env sigma ->
    let constr, ustate = Constrintern.interp_constr env sigma parsed_term in
    let sigma = Evd.merge_ustate sigma ustate in
    Proofview.Unsafe.tclEVARS sigma >>
    return constr
  end

let open_constr_of_string s =
  let parsed_term = parse_constrexpr s in
  with_env begin fun env sigma ->
    let sigma, econstr = Constrintern.interp_open_constr env sigma parsed_term in
    Proofview.Unsafe.tclEVARS sigma >>
    return econstr
  end

(** {1 Parsing with antiquotations} *)

type genarg_antiquotation =
  [ `Constr of EConstr.constr         (** {v %{…} v} or {v %constr:{…} v} *)
  | `Preterm of Glob_term.glob_constr (** {v %preterm:{…} v} *)
  ]

type antiquotation =
  [ genarg_antiquotation
  | `Expr of Constrexpr.constr_expr   (** {v %expr:{…} v} *)
  ]

(** {2 Generic arguments} *)

(** As a performance optimization, we interpret {v %preterm:{…} v} and
    {v %constr:{…} v} as generic arguments, so that we don't have to
    re-globalize/re-typecheck the given terms. *)

let wit_antiquotation : (genarg_antiquotation, genarg_antiquotation) GenConstr.tag =
  GenConstr.create "mltac:antiquotation"

(* Internalization is the identity function. *)
let () =
  Genintern.register_intern_constr wit_antiquotation (fun ?loc _ v -> v)

let interp_constr_antiquotation ?loc env sigma tycon c =
  let judgment = Retyping.get_judgment_of env sigma c in
  match tycon with
  | None -> judgment, sigma
  | Some ty ->
     (* Recheck judgement against the typing condition. *)
     let sigma =
       try Evarconv.unify_leq_delay env sigma judgment.uj_type ty
       with Evarconv.UnableToUnify (sigma, e) ->
         Pretype_errors.error_actual_type ?loc env sigma judgment ty e
     in
     { judgment with uj_type = ty }, sigma

let interp_preterm_antiquotation env sigma tycon t =
  let open Pretyping in
  let tycon =
    match tycon with
    | Some ty -> OfType ty
    | None -> WithoutTypeConstraint
  in
  let sigma, t, ty =
    Pretyping.understand_tcc_ty
      ~flags:(Ltac2_plugin.Tac2core.preterm_flags)
      ~expected_type:tycon
      env sigma t
  in
  Environ.make_judge t ty, sigma

let () =
  let interp ?loc ~poly env sigma tycon =
    let env = GlobEnv.renamed_env env in
    function
    | `Constr c -> interp_constr_antiquotation ?loc env sigma tycon c
    | `Preterm t -> interp_preterm_antiquotation env sigma tycon t
  in
  GlobEnv.register_constr_interp0 wit_antiquotation interp

(* Module substitution does not affect our antiquotations. *)
let () =
  Gensubst.register_constr_subst wit_antiquotation (fun _ v -> v)

let () =
  let print_antiquotation antiquotation =
    let open Pp in
    Genprint.PrinterBasic (fun env sigma ->
      match antiquotation with
      | `Constr c -> str "%{"
      | `Preterm t -> str "%preterm:{"
    )
  in
  Genprint.register_constr_print wit_antiquotation print_antiquotation print_antiquotation

(** {2 Camlp5 grammar tricks} *)

(** Generic production rule for antiquotations:
    [[ [ "%{"; x = ident; "}" -> { f x } ] ]]
 *)
let antiquotation_production f =
  let open Procq in
  Production.make
    (Rule.next
       (Rule.next
          (Rule.next (Procq.Rule.stop)
             ((Symbol.token (Tok.PKEYWORD ("%{")))))
          ((Symbol.nterm Constr.ident)))
       ((Symbol.token (Tok.PKEYWORD ("}")))))
    (fun _ x _ loc -> f ~loc x)

(** Execute function [f] in synterp phase. This function is a hack that tricks
    Rocq by temporarily setting the [Flags.in_synterp] flag. *)
let with_synterp f =
  let old = !Flags.in_synterp_phase in
  Flags.in_synterp_phase := Some true;
  Fun.protect
    ~finally:(fun () -> Flags.in_synterp_phase := old)
    f

(** Execute function [f] where [entry] allows anti-quotations in the map
    [context]. *)
let with_antiquotations entry antiquotation_to_constrexpr f =
  with_synterp (fun () ->
    let grammar_state = Procq.freeze () in
    let () =
      Egramml.grammar_extend ~ignore_kw:false
        entry
        (Reuse (Some "0", [antiquotation_production antiquotation_to_constrexpr]))
    in
    Fun.protect
      ~finally:(fun () -> Procq.unfreeze grammar_state)
      f
  )

(** {2 Quasiparsing methods} *)

let quasiparse_constrexpr s context =
  let antiquotation_to_constrexpr ~loc = function
    | `Expr e -> e
    | #genarg_antiquotation as antiquotation ->
       let open Constrexpr in
       let genarg = CGenarg (GenConstr.Raw (wit_antiquotation, antiquotation)) in
       CAst.make ~loc genarg
  in
  with_antiquotations Procq.Constr.term
    (fun ~loc x -> antiquotation_to_constrexpr ~loc (Id.Map.find x context))
    (fun () -> parse_constrexpr s)

let glob_constr_of_quasistring s context =
  with_env begin fun env sigma ->
    return (Constrintern.intern_constr env sigma (quasiparse_constrexpr s context))
  end

let constr_of_quasistring s context =
  with_env begin fun env sigma ->
    let constr, ustate = Constrintern.interp_constr env sigma (quasiparse_constrexpr s context) in
    let sigma = Evd.merge_ustate sigma ustate in
    Proofview.Unsafe.tclEVARS sigma >>
    return constr
  end

let open_constr_of_quasistring s context =
  with_env begin fun env sigma ->
    let sigma, econstr = Constrintern.interp_open_constr env sigma (quasiparse_constrexpr s context) in
    Proofview.Unsafe.tclEVARS sigma >>
    return econstr
  end
