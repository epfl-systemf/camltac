(** Registration of PPX rewriters for quoting Rocq code. *)

open Ppxlib
open Expansion_helpers

(** {1 Extensions with string interpolation} *)

(** Extensions [[%ident]], [[%qualid]], [[%vernac]] support a limited subset of
    antiquotations in the form of string interpolation. *)

module Ident = struct
  let expand ~ctxt s =
    let loc = Expansion_context.Extension.extension_point_loc ctxt in
    let s = Ast_builder.Default.estring ~loc s in
    [%expr Runtime.Parsing.parse_ident [%string [%e s]]]

  let extension =
    Extension.V3.declare
      "ident"
      Extension.Context.expression
      Ast_pattern.(single_expr_payload (estring __))
      expand
end

module Qualid = struct
  let expand ~ctxt s =
    let loc = Expansion_context.Extension.extension_point_loc ctxt in
    let s = Ast_builder.Default.estring ~loc s in
    [%expr Runtime.Parsing.parse_qualid [%string [%e s]]]

  let extension =
    Extension.V3.declare
      "qualid"
      Extension.Context.expression
      Ast_pattern.(single_expr_payload (estring __))
      expand
end

module Vernac = struct
  let expand ~ctxt s =
    let loc = Expansion_context.Extension.extension_point_loc ctxt in
    let s = Ast_builder.Default.estring ~loc s in
    [%expr Runtime.Parsing.parse_vernac [%string [%e s]]]

  let extension =
    Extension.V3.declare
      "vernac"
      Extension.Context.expression
      Ast_pattern.(single_expr_payload (estring __))
      expand
end

(** {1 Extensions with antiquotations} *)

(** Extensions [[%expr]], [[%glob_constr]], and [[%constr]] support term
    antiquotations. *)

let build_antiquotation_list bindings ~loc =
  let binding_to_expr (expr, typ) =
    match typ with
    | Quasiquotation.Unspecified | Constr -> [%expr `Constr [%e expr]]
    | Preterm -> [%expr `Preterm [%e expr]]
    | Expr -> [%expr `Expr [%e expr]]
  in
  let bindings = List.map binding_to_expr bindings in
  Ppx_utils.expr_of_list ~loc bindings

(** {2 [Constrexpr.constr_expr] *)

module Expr = struct
  let expand ~ctxt ~loc s =
    let fragments = Quasiquotation.parse ~loc s in
    let template, bindings = Quasiquotation.generate_template fragments in
    let template = Ast_builder.Default.estring ~loc template in
    match bindings with
    | [] -> [%expr Runtime.Parsing.parse_constrexpr [%e template]]
    | _ ->
       [%expr
         let context = [%e build_antiquotation_list bindings ~loc] in
         Runtime.Parsing.quasiparse_constrexpr [%e template] context]

  let extension =
    Extension.V3.declare
      "expr"
      Extension.Context.expression
      Ast_pattern.(single_expr_payload (pexp_constant (pconst_string __ __ drop)))
      (fun ~ctxt s loc -> expand ~ctxt ~loc s)
end

(** {2 [Glob_term.glob_constr] *)

module Preterm = struct
  let expand ~ctxt ~loc s =
    let fragments = Quasiquotation.parse ~loc s in
    let template, bindings = Quasiquotation.generate_template fragments in
    let template = Ast_builder.Default.estring ~loc template in
    match bindings with
    | [] -> [%expr Runtime.Parsing.glob_constr_of_string [%e template]]
    | _ ->
       [%expr
         let context = [%e build_antiquotation_list bindings ~loc] in
         Runtime.Parsing.glob_constr_of_quasistring [%e template] context]

  let extension =
    Extension.V3.declare
      "preterm"
      Extension.Context.expression
      Ast_pattern.(single_expr_payload (pexp_constant (pconst_string __ __ drop)))
      (fun ~ctxt s loc -> expand ~ctxt ~loc s)
end

(** {2 [EConstr.constr] and [EConstr.t] *)

module Constr = struct
  let expand ~ctxt ~loc s =
    let fragments = Quasiquotation.parse ~loc s in
    let template, bindings = Quasiquotation.generate_template fragments in
    let template = Ast_builder.Default.estring ~loc template in
    match bindings with
    | [] -> [%expr Runtime.Parsing.constr_of_string [%e template]]
    | _ ->
       [%expr
         let context = [%e build_antiquotation_list bindings ~loc] in
         Runtime.Parsing.constr_of_quasistring [%e template] context]

  let extension =
    Extension.V3.declare
      "constr"
      Extension.Context.expression
      Ast_pattern.(single_expr_payload (pexp_constant (pconst_string __ __ drop)))
      (fun ~ctxt s loc -> expand ~ctxt ~loc s)

  type case =
    { lhs: string loc option;
      rhs: expression loc }

  let expand_match ~ctxt ~loc ~scrutinee ~cases =
    let expand_case { lhs; rhs } =
      let lhs, bindings =
        match lhs with
        | Some { txt = pattern; loc } ->
           (* Compute the set of metavariables used by [pattern] at
              compilation-time by parsing it. Note that we have to reparse the
              pattern at runtime, since there is no easy way to splice the
              obtained pattern back into the generated source code. *)
           let parsed_pattern = Runtime.Parsing.parse_pattern pattern in
           let bindings = Runtime.Pattern_matching.pattern_variables parsed_pattern in
           let f { CAst.v = id; loc = id_loc } =
             let id = Names.Id.to_string id in
             let loc =
               match id_loc with
               | Some loc -> Ppx_utils.loc_of_rocq_loc loc
               | None -> loc (* Default to using the whole pattern location *)
             in
             let id_expr = Ast_builder.Default.estring ~loc id in
             { txt = id; loc }, [%expr Names.Id.Map.find (Names.Id.of_string [%e id_expr]) subst]
           in
           let bindings = List.map f bindings in
           let pattern = Ast_builder.Default.estring ~loc pattern in
           [%expr Runtime.Parsing.parse_pattern [%e pattern]], bindings
        | None -> [%expr Runtime.Parsing.parse_pattern "_"], []
      in
      let { txt = rhs; loc } = rhs in
      let rhs = [%expr fun subst -> [%e Ppx_utils.with_let_bindings ~loc bindings rhs]] in
      [%expr ([%e lhs], [%e rhs])]
    in
    let cases = List.map expand_case cases in
    let cases = Ppx_utils.expr_of_list ~loc cases in
    [%expr Runtime.Pattern_matching.match_term [%e scrutinee] ~cases:[%e cases]]

  let match_extension =
    let case_pattern = Ast_pattern.(
        case
          ~lhs:(alt_option (pstring __') ppat_any)
          ~guard:(none)
          ~rhs:(__'))
    in
    let case_pattern = Ast_pattern.(map ~f:(fun f lhs rhs -> f { lhs; rhs }) case_pattern) in
    Extension.V3.declare
      "pat"
      Extension.Context.expression
      Ast_pattern.(single_expr_payload (pexp_match __' (many case_pattern)))
      (fun ~ctxt scrutinee cases -> expand_match ~ctxt ~loc:scrutinee.loc ~scrutinee:scrutinee.txt ~cases)
end

module Open_constr = struct
  let expand ~ctxt ~loc s =
    let fragments = Quasiquotation.parse ~loc s in
    let template, bindings = Quasiquotation.generate_template fragments in
    let template = Ast_builder.Default.estring ~loc template in
    match bindings with
    | [] -> [%expr Runtime.Parsing.open_constr_of_string [%e template]]
    | _ ->
       [%expr
          let context = [%e build_antiquotation_list bindings ~loc] in
          Runtime.Parsing.open_constr_of_quasistring [%e template] context]

  let extension =
    Extension.V3.declare
      "open_constr"
      Extension.Context.expression
      Ast_pattern.(single_expr_payload (pexp_constant (pconst_string __ __ drop)))
      (fun ~ctxt s loc -> expand ~ctxt ~loc s)
end

(**/**)

let () =
  Ppxlib.Driver.register_transformation
    ~extensions:[
      Ident.extension;
      Qualid.extension;
      Vernac.extension;

      Expr.extension;
      Preterm.extension;
      Constr.extension;
      Constr.match_extension;
      Open_constr.extension
    ]
    "mltac"
