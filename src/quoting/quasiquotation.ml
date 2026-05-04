open Ppxlib

type antiquotation_kind =
  | Unspecified
  | Constr
  | Preterm
  | Expr

type fragment =
| Literal of string
| Antiquoted of antiquotation_kind * expression

let make_error ~loc fmt args =
  Ast_builder.Default.pexp_extension ~loc @@
    Location.error_extensionf ~loc fmt args

let parse_expression s ~loc =
  let lexbuf = Lexing.from_string s in
  Lexing.set_position lexbuf loc.loc_start;
  Lexing.set_filename lexbuf loc.loc_start.pos_fname;
  try Parse.expression lexbuf
  with _ -> make_error ~loc "Invalid antiquotation: %S" s

let parse_antiquotation_kind = function
  | "constr:" -> Constr
  | "preterm:" -> Preterm
  | "expr:" -> Expr
  | _ -> assert false

let rec parse ~loc s =
  let rec parse stream =
    let literal, stream = CharStream.span ~pattern:{|%\(\(constr:\)\|\(preterm:\)\|\(expr:\)\)?{|} stream in
    if CharStream.is_empty stream then
      [Literal literal]
    else
      let matched_start = Str.matched_group 0 stream.contents in
      let antiquotation_kind =
        try parse_antiquotation_kind (Str.matched_group 1 stream.contents)
        with Not_found -> Unspecified
      in
      let stream = CharStream.advance ~n:(String.length matched_start) stream in
      let antiquotation, stream = CharStream.located_span ~pattern:"}" stream in
      if CharStream.is_empty stream then
        let error = make_error ~loc:antiquotation.loc "Unclosed antiquotation: %S" antiquotation.txt in
        [Literal literal; Antiquoted (antiquotation_kind, error)]
      else
        let stream = CharStream.advance ~n:1 stream in
        let expr = parse_expression antiquotation.txt ~loc:antiquotation.loc in
        Literal literal :: Antiquoted (antiquotation_kind, expr) :: parse stream
  in
  parse (CharStream.of_string s ~loc)

let generate_template fragments =
  let rec process fragments next_id =
    match fragments with
    | [] -> "", []
    | Literal l :: rest ->
       let template, bindings = process rest next_id in
       l ^ template, bindings
    | Antiquoted (kind, e) :: rest ->
       let template, bindings = process rest (next_id + 1) in
       "%{" ^ string_of_int next_id ^ "}" ^ template, (e, kind) :: bindings
  in
  process fragments 0
