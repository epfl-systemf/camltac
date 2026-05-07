(** API for parsing terms. *)

open Names
open Api
open Terms

let parse ?loc entry s = Procq.parse_string ?loc entry s

(* Entries registered at synterp time. *)
let constrexpr     = Procq.eoi_entry Procq.Constr.term
let ident          = Procq.eoi_entry Procq.Constr.ident
let qualid         = Procq.eoi_entry Procq.Prim.qualid
let match_pattern  = Procq.eoi_entry Procq.Constr.cpattern
let vernac_control = Procq.eoi_entry Pvernac.Vernac_.vernac_control
let ltac           = Procq.eoi_entry Ltac_plugin.Pltac.tactic
let ltac2          = Procq.eoi_entry Ltac2_plugin.G_ltac2.ltac2_expr

let parse_constrexpr ?loc    = parse ?loc constrexpr
let parse_ident ?loc         = parse ?loc ident
let parse_qualid ?loc        = parse ?loc qualid
let parse_vernac ?loc        = parse ?loc vernac_control
let parse_ltac ?loc          = parse ?loc ltac
let parse_ltac2 ?loc         = parse ?loc ltac2
let parse_match_pattern ?loc = parse ?loc match_pattern

let glob_constr_of_string ?loc s =
  let parsed_term = parse_constrexpr ?loc s in
  Glob_constr.of_constrexpr parsed_term

let constr_of_string ?loc s =
  let parsed_term = parse_constrexpr ?loc s in
  Constr.of_constrexpr parsed_term

let open_constr_of_string ?loc s =
  let parsed_term = parse_constrexpr ?loc s in
  Open_constr.of_constrexpr parsed_term

(** {1 Parsing with antiquotations} *)

type genarg_antiquotation =
  [ `Constr of constr       (** {v %{…} v} or {v %constr:{…} v} *)
  | `Preterm of glob_constr (** {v %preterm:{…} v} *)
  ]

type antiquotation =
  [ genarg_antiquotation
  | `Expr of constrexpr (** {v %expr:{…} v} *)
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
  let print_antiquotation (antiquotation: genarg_antiquotation) =
    let open Pp in
    Genprint.PrinterBasic (fun env sigma ->
      match antiquotation with
      | `Constr c -> str "%{" ++ Printer.pr_econstr_env env sigma c ++ str "}"
      | `Preterm t -> str "%preterm:{" ++ Printer.pr_glob_constr_env env sigma t ++ str "}"
    )
  in
  Genprint.register_constr_print wit_antiquotation print_antiquotation print_antiquotation

(** {2 Camlp5 grammar tricks} *)

(** Generic production rule for antiquotations:
    [[ [ "%{"; n = natural; "}" -> { f n } ] ]]
 *)
let antiquotation_production f =
  let open Procq in
  Production.make
    (Rule.next
       (Rule.next
          (Rule.next (Procq.Rule.stop)
             ((Symbol.token (Tok.PKEYWORD ("%{")))))
          ((Symbol.nterm Prim.natural)))
       ((Symbol.token (Tok.PKEYWORD ("}")))))
    (fun _ n _ loc -> f ~loc n)

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

let quasiparse_constrexpr ?loc s context =
  let antiquotation_to_constrexpr ~loc : antiquotation -> constrexpr = function
    | `Expr e -> e
    | #genarg_antiquotation as antiquotation ->
       let open Constrexpr in
       let genarg = CGenarg (GenConstr.Raw (wit_antiquotation, antiquotation)) in
       CAst.make ~loc genarg
  in
  with_antiquotations Procq.Constr.term
    (fun ~loc n -> antiquotation_to_constrexpr ~loc (List.nth context n))
    (fun () -> parse_constrexpr ?loc s)

let glob_constr_of_quasistring ?loc s context =
  let parsed_term = quasiparse_constrexpr ?loc s context in
  Glob_constr.of_constrexpr parsed_term

let constr_of_quasistring ?loc s context =
  let parsed_term = quasiparse_constrexpr ?loc s context in
  Constr.of_constrexpr parsed_term

let open_constr_of_quasistring ?loc s context =
  let parsed_term = quasiparse_constrexpr ?loc s context in
  Open_constr.of_constrexpr parsed_term
