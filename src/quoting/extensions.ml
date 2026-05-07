(** Registration of PPX rewriters for quoting Rocq code. *)

open Ppxlib
open Expansion_helpers

(** {1 Extensions with string interpolation} *)

(** Extensions [[%ident]], [[%qualid]], [[%vernac]] support a limited subset of
    antiquotations in the form of string interpolation. *)

module Ident = struct
  let expand ~ctxt string string_loc =
    let loc = Expansion_context.Extension.extension_point_loc ctxt in
    let string_expr = Ast_builder.Default.estring ~loc:string_loc string in
    let rocq_loc = Ppx_utils.rocq_loc_of_loc string_loc in
    [%expr Runtime.Parsing.parse_ident ~loc:[%e rocq_loc] [%string [%e string_expr]]]

  let extension =
    Extension.V3.declare
      "ident"
      Extension.Context.expression
      Ast_pattern.(single_expr_payload (pexp_constant (pconst_string __ __ drop)))
      expand
end

module Qualid = struct
  let expand ~ctxt string string_loc =
    let loc = Expansion_context.Extension.extension_point_loc ctxt in
    let string_expr = Ast_builder.Default.estring ~loc:string_loc string in
    let rocq_loc = Ppx_utils.rocq_loc_of_loc string_loc in
    [%expr Runtime.Parsing.parse_qualid ~loc:[%e rocq_loc] [%string [%e string_expr]]]

  let extension =
    Extension.V3.declare
      "qualid"
      Extension.Context.expression
      Ast_pattern.(single_expr_payload (pexp_constant (pconst_string __ __ drop)))
      expand
end

module Vernac = struct
  let expand ~ctxt string string_loc =
    let loc = Expansion_context.Extension.extension_point_loc ctxt in
    let string_expr = Ast_builder.Default.estring ~loc:string_loc string in
    let rocq_loc = Ppx_utils.rocq_loc_of_loc string_loc in
    [%expr Runtime.Parsing.parse_vernac ~loc:[%e rocq_loc] [%string [%e string_expr]]]

  let extension =
    Extension.V3.declare
      "vernac"
      Extension.Context.expression
      Ast_pattern.(single_expr_payload (pexp_constant (pconst_string __ __ drop)))
      expand
end

(** {1 Extensions with antiquotations} *)

(** Extensions [[%expr]], [[%glob_constr]], and [[%constr]] support term
    antiquotations. *)

let build_antiquotation_list bindings ~loc =
  let binding_to_expr (expr, typ) =
    match typ with
    | Quasiquotation.Unspecified | Constr -> [%expr `Constr ([%e expr]: EConstr.constr)]
    | Preterm -> [%expr `Preterm ([%e expr]: Glob_term.glob_constr)]
    | Expr -> [%expr `Expr ([%e expr]: Constrexpr.constr_expr)]
  in
  let bindings = List.map binding_to_expr bindings in
  Ast_builder.Default.elist ~loc bindings

let expand_antiquotation parser quasiparser ~ctxt string string_loc =
  let loc = Expansion_context.Extension.extension_point_loc ctxt in
  let template, bindings =
    Quasiquotation.parse ~loc:string_loc string |>
    Quasiquotation.generate_template
  in
  let template = Ast_builder.Default.estring ~loc:string_loc template in
  let rocq_loc = Ppx_utils.rocq_loc_of_loc string_loc in
  match bindings with
  | [] -> [%expr [%e parser] ~loc:[%e rocq_loc] [%e template]]
  | _ ->
     [%expr
      let context = [%e build_antiquotation_list bindings ~loc] in
      [%e quasiparser] ~loc:[%e rocq_loc] [%e template] context]

(** {2 [Constrexpr.constr_expr]} *)

module Expr = struct
  let expand ~ctxt =
    let loc = Expansion_context.Extension.extension_point_loc ctxt in
    let parser = [%expr Runtime.Parsing.parse_constrexpr] in
    let quasiparser = [%expr Runtime.Parsing.quasiparse_constrexpr] in
    expand_antiquotation parser quasiparser ~ctxt

  let extension =
    Extension.V3.declare
      "expr"
      Extension.Context.expression
      Ast_pattern.(single_expr_payload (pexp_constant (pconst_string __ __ drop)))
      expand
end

(** {2 [Glob_term.glob_constr]} *)

module Preterm = struct
  let expand ~ctxt =
    let loc = Expansion_context.Extension.extension_point_loc ctxt in
    let parser = [%expr Runtime.Parsing.glob_constr_of_string] in
    let quasiparser = [%expr Runtime.Parsing.glob_constr_of_quasistring] in
    expand_antiquotation parser quasiparser ~ctxt

  let extension =
    Extension.V3.declare
      "preterm"
      Extension.Context.expression
      Ast_pattern.(single_expr_payload (pexp_constant (pconst_string __ __ drop)))
      expand
end

(** {2 [EConstr.constr] and [EConstr.t]} *)

module Constr = struct
  type constr_payload =
    | String of string loc
    | Match of {
        scrutinee: expression;
        cases: match_case list
      }
  and match_case = {
    lhs: string option loc; (** Pattern string, or [None] if the case is catch-all. *)
    rhs: expression loc     (** Expression to execute when the pattern matches. *)
  }

  let expand_string ~ctxt =
    let loc = Expansion_context.Extension.extension_point_loc ctxt in
    let parser = [%expr Runtime.Parsing.constr_of_string] in
    let quasiparser = [%expr Runtime.Parsing.constr_of_quasistring] in
    expand_antiquotation parser quasiparser ~ctxt

  let string_pattern =
    let pattern = Ast_pattern.(pexp_constant (pconst_string __ __ drop)) in
    Ast_pattern.(map ~f:(fun f label loc -> f (String { txt = label; loc })) pattern)

  let expand_pattern_var { txt = id; loc } =
    let id_expr = Ast_builder.Default.estring ~loc id in
    { txt = id; loc }, [%expr Names.Id.Map.find (Names.Id.of_string [%e id_expr]) subst]

  let find_all_pattern_vars ~loc pattern =
    let rec find_all_in_stream stream =
      let _, stream = CharStream.span ~pattern:{|@?\?|} stream in
      if CharStream.is_empty stream then []
      else
        let prefix = Str.matched_string stream.contents in
        let loc_start = stream.pos in
        let stream = CharStream.advance ~n:(String.length prefix) stream in
        (* Attempt to parse an identifier from the rest of the stream *)
        try
          let rest = CharStream.take_all stream in
          let id = Names.Id.to_string (Runtime.Parsing.parse Procq.Prim.ident rest) in
          let stream = CharStream.advance ~n:(String.length id) stream in
          let loc_end = stream.pos in
          let loc = { loc_start; loc_end; loc_ghost = false } in
          { txt = id; loc } :: find_all_in_stream stream
        with Gramlib.Grammar.ParseError _ ->
          (* Failed to parse an identifier: most likely a false positive. *)
          find_all_in_stream stream
    in
    let stream = CharStream.of_string ~loc pattern in
    find_all_in_stream stream

  let expand_case ~loc { lhs = { txt = lhs; loc = lhs_loc }; rhs = { txt = rhs; loc = rhs_loc } } =
    let rocq_loc = Ppx_utils.rocq_loc_of_loc lhs_loc in
    let lhs, bindings =
      match lhs with
      | Some pattern ->
         (** Approximate the set of metavariables used by [pattern] at
             compilation-time by finding all occurrences of {v ?x v} or {v @?x v}.
             Note that parsing is not available since Rocq is not loaded,
             and therefore patterns such as {v ?x + ?y v} would fail to parse correctly. *)
         let bindings = find_all_pattern_vars ~loc:lhs_loc pattern in
         let bindings = List.map expand_pattern_var bindings in
         let pattern_expr = Ast_builder.Default.estring ~loc:lhs_loc pattern in
         [%expr Runtime.Parsing.parse_match_pattern ~loc:[%e rocq_loc] [%e pattern_expr]], bindings
      | None -> [%expr Runtime.Parsing.parse_match_pattern ~loc:[%e rocq_loc] "_"], []
    in
    let rhs = [%expr fun subst -> [%e Ppx_utils.with_let_bindings ~loc bindings rhs]] in
    [%expr ([%e lhs], [%e rhs])]

  let expand_match ~ctxt ~scrutinee ~cases =
    let loc = Expansion_context.Extension.extension_point_loc ctxt in
    let cases = List.map (expand_case ~loc) cases in
    let cases = Ast_builder.Default.elist ~loc cases in
    [%expr Runtime.Pattern_matching.match_term [%e scrutinee] ~cases:[%e cases]]

  let match_pattern =
    let regular_pattern = Ast_pattern.(
        map ~f:(fun f s loc -> f { txt = Some s; loc }) @@
          ppat_constant (pconst_string __ __ drop))
    in
    let any_pattern = Ast_pattern.(
        map ~f:(fun f loc -> f { txt = None; loc }) @@
          ppat_loc __ ppat_any)
    in
    let case_pattern = Ast_pattern.(
        case
          ~lhs:(alt regular_pattern any_pattern)
          ~guard:(none)
          ~rhs:(__'))
    in
    let case_pattern = Ast_pattern.(map ~f:(fun f lhs rhs -> f { lhs; rhs }) case_pattern) in
    let match_pattern = Ast_pattern.(pexp_match __ (many case_pattern)) in
    Ast_pattern.(map ~f:(fun f scrutinee cases -> f (Match { scrutinee; cases })) match_pattern)

  let extension =
    Extension.V3.declare
      "constr"
      Extension.Context.expression
      Ast_pattern.(single_expr_payload (alt string_pattern match_pattern))
      (fun ~ctxt payload ->
        match payload with
        | String { txt = s; loc = s_loc } -> expand_string ~ctxt s s_loc
        | Match { scrutinee; cases } -> expand_match ~ctxt ~scrutinee ~cases)
end

module Open_constr = struct
  let expand ~ctxt =
    let loc = Expansion_context.Extension.extension_point_loc ctxt in
    let parser = [%expr Runtime.Parsing.open_constr_of_string] in
    let quasiparser = [%expr Runtime.Parsing.open_constr_of_quasistring] in
    expand_antiquotation parser quasiparser ~ctxt

  let extension =
    Extension.V3.declare
      "open_constr"
      Extension.Context.expression
      Ast_pattern.(single_expr_payload (pexp_constant (pconst_string __ __ drop)))
      expand
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
