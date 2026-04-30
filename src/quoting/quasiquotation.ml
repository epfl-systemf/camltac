open Ppxlib

type antiquotation_kind =
  | Unspecified
  | Constr
  | Preterm
  | Expr

type fragment =
| Literal of string
| Antiquoted of antiquotation_kind * expression

module CharStream = struct

  type t =
    { contents: string; (** Contents of the stream. *)
      pos: position;    (** Current position of the stream inside the file. *)
      index: int;       (** Index of the current position in the stream contents. *)
      length: int;      (** Length of the stream. *)
    }

  let of_string contents ~loc =
    { contents;
      pos = loc.loc_start;
      index = 0;
      length = String.length contents;
    }

  let is_empty stream =
    stream.index >= stream.length

  (** [advance ~n stream] consumes [n] characters of the stream. *)
  let advance ~n stream =
    assert (n >= 0);
    let rec advance_pos ~n ~pos ~index =
      if n = 0 then pos
      else
        let next_cnum = pos.pos_cnum + 1 in
        let next_pos =
          match stream.contents.[index] with
          | '\n' ->
             { pos with pos_lnum = pos.pos_lnum + 1;
                        pos_cnum = next_cnum;
                        pos_bol  = next_cnum }
          | _ -> { pos with pos_cnum = next_cnum }
        in
        advance_pos ~n:(n - 1) ~pos:next_pos ~index:(index + 1)
    in
    let pos = advance_pos ~n ~pos:stream.pos ~index:stream.index in
    { stream with pos; index = stream.index + n }

  (** [take ~n] returns the next [n] characters of the stream. *)
  let take ~n stream =
    assert (n >= 0);
    if is_empty stream then ""
    else String.sub stream.contents stream.index n

  (** [span ~pattern stream] return the prefix of [stream] until the first
      occurrence of [pattern], as well as the remaining stream. *)
  let span ~pattern stream =
    if is_empty stream then "", stream
    else
      let regexp = Str.regexp pattern in
      let until =
        try Str.search_forward regexp stream.contents stream.index
        with Not_found -> stream.length
      in
      let prefix_size = until - stream.index in
      take ~n:prefix_size stream,
      advance ~n:prefix_size stream

  let located_span ~pattern stream =
    let prefix, tail = span ~pattern stream in
    let prefix_loc = { loc_start = stream.pos; loc_end = tail.pos; loc_ghost = false } in
    { txt = prefix; loc = prefix_loc }, tail
end

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
