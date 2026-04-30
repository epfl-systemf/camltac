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

let build_context_map bindings typ ~loc =
  let rec to_expr = function
    | [] -> [%expr []]
    | (name, expr) :: rest ->
       let rest = to_expr rest in
       let name = Ast_builder.Default.estring ~loc name in
       [%expr (Names.Id.of_string [%e name], ([%e expr] : [%t typ])) :: [%e rest]]
  in
  [%expr Names.Id.Map.of_list [%e to_expr bindings]]

(** {2 [Constrexpr.constr_expr] *)

module Expr = struct
  let expand ~ctxt ~loc s =
    let fragments = Quasiquotation.parse ~loc s in
    let expressions, s = Quasiquotation.extract_expressions fragments in
    let s = Ast_builder.Default.estring ~loc s in
    match expressions with
    | [] -> [%expr Runtime.Parsing.parse_constrexpr [%e s]]
    | _ ->
       [%expr
        let context = [%e build_context_map expressions [%type: Constrexpr.constr_expr] ~loc] in
            Runtime.Parsing.quasiparse_constrexpr [%e s] context]

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
    let expressions, s = Quasiquotation.extract_expressions fragments in
    let s = Ast_builder.Default.estring ~loc s in
    match expressions with
    | [] -> [%expr Runtime.Parsing.glob_constr_of_string [%e s]]
    | _ ->
       [%expr
        let context = [%e build_context_map expressions [%type: EConstr.constr] ~loc] in
            Runtime.Parsing.glob_constr_of_quasistring [%e s] context]

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
    let expressions, s = Quasiquotation.extract_expressions fragments in
    let s = Ast_builder.Default.estring ~loc s in
    match expressions with
    | [] -> [%expr Runtime.Parsing.constr_of_string [%e s]]
    | _ ->
       [%expr
        let context = [%e build_context_map expressions [%type: EConstr.constr] ~loc] in
            Runtime.Parsing.constr_of_quasistring [%e s] context]

  let extension =
    Extension.V3.declare
      "constr"
      Extension.Context.expression
      Ast_pattern.(single_expr_payload (pexp_constant (pconst_string __ __ drop)))
      (fun ~ctxt s loc -> expand ~ctxt ~loc s)
end

module Open_constr = struct
  let expand ~ctxt ~loc s =
    let fragments = Quasiquotation.parse ~loc s in
    let expressions, s = Quasiquotation.extract_expressions fragments in
    let s = Ast_builder.Default.estring ~loc s in
    match expressions with
    | [] -> [%expr Runtime.Parsing.open_constr_of_string [%e s]]
    | _ ->
       [%expr
        let context = [%e build_context_map expressions [%type: EConstr.t] ~loc] in
            Runtime.Parsing.open_constr_of_quasistring [%e s] context]

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
      Open_constr.extension
    ]
    "mltac"
