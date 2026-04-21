(** Registration of PPX rewriters for quoting Rocq code. *)

open Ppxlib

let ident_expansion ~ctxt s =
  let loc = Expansion_context.Extension.extension_point_loc ctxt in
  let s = Ast_builder.Default.estring ~loc s in
  [%expr let open Api in Parsing.parse_ident [%e s]]

let qualid_expansion ~ctxt s =
  let loc = Expansion_context.Extension.extension_point_loc ctxt in
  let s = Ast_builder.Default.estring ~loc s in
  [%expr let open Api in Parsing.parse_qualid [%e s]]

let constrexpr_expansion ~ctxt s =
  let loc = Expansion_context.Extension.extension_point_loc ctxt in
  let s = Ast_builder.Default.estring ~loc s in
  [%expr let open Api in Parsing.parse_constrexpr [%e s]]

let glob_constr_expansion ~ctxt s =
  let loc = Expansion_context.Extension.extension_point_loc ctxt in
  let s = Ast_builder.Default.estring ~loc s in
  [%expr let open Api in Parsing.glob_constr_of_string [%e s]]

let constr_expansion ~ctxt s =
  let loc = Expansion_context.Extension.extension_point_loc ctxt in
  let s = Ast_builder.Default.estring ~loc s in
  [%expr let open Api in Parsing.constr_of_string [%e s]]

let open_constr_expansion ~ctxt s =
  let loc = Expansion_context.Extension.extension_point_loc ctxt in
  let s = Ast_builder.Default.estring ~loc s in
  [%expr let open Api in Parsing.open_constr_of_string [%e s]]

let vernac_expansion ~ctxt s =
  let loc = Expansion_context.Extension.extension_point_loc ctxt in
  let s = Ast_builder.Default.estring ~loc s in
  [%expr let open Api in Parsing.parse_vernac [%e s]]

let ident =
  Extension.V3.declare
    "ident"
    Extension.Context.expression
    Ast_pattern.(single_expr_payload (estring __))
    ident_expansion

let qualid =
  Extension.V3.declare
    "qualid"
    Extension.Context.expression
    Ast_pattern.(single_expr_payload (estring __))
    qualid_expansion

let expr =
  Extension.V3.declare
    "expr"
    Extension.Context.expression
    Ast_pattern.(single_expr_payload (estring __))
    constrexpr_expansion

let preterm =
  Extension.V3.declare
    "preterm"
    Extension.Context.expression
    Ast_pattern.(single_expr_payload (estring __))
    glob_constr_expansion

let constr =
  Extension.V3.declare
    "constr"
    Extension.Context.expression
    Ast_pattern.(single_expr_payload (estring __))
    constr_expansion

let open_constr =
  Extension.V3.declare
    "open_constr"
    Extension.Context.expression
    Ast_pattern.(single_expr_payload (estring __))
    open_constr_expansion

let vernac =
  Extension.V3.declare
    "vernac"
    Extension.Context.expression
    Ast_pattern.(single_expr_payload (estring __))
    vernac_expansion

let () =
  Ppxlib.Driver.register_transformation
    ~extensions:[ident; qualid; expr; preterm; constr; open_constr; vernac]
    "mltac"
