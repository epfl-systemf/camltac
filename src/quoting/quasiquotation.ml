open Ppxlib

type fragment =
| Literal of string
| Antiquoted of expression

module CharStream = struct

  type t =
    { contents: string;
      length: int;
      loc: location;
      pos: position;
      index: int }

  let of_string contents ~loc =
    { contents;
      length = String.length contents;
      loc;
      pos = loc.loc_start;
      index = 0 }

  let is_empty stream =
    stream.index >= stream.length

  let advance_char pos char =
    let pos_cnum = pos.pos_cnum + 1 in
    match char with
    | '\n' ->
      { pos with pos_lnum = pos.pos_lnum + 1; pos_bol = pos_cnum; pos_cnum }
    | _ -> { pos with pos_cnum }

  let advance ~n stream =
    assert (n >= 0);
    let pos = ref stream.pos in
    for i = 0 to n - 1 do
      pos := advance_char !pos stream.contents.[stream.index + i]
    done;
    { stream with pos = !pos; index = stream.index + n }

  (** [span ~pattern stream] return the prefix of [stream] until the first
      occurrence of [pattern], as well as the remaining stream. *)
  let span ~pattern stream =
    if is_empty stream then "", stream
    else
      let regexp = Str.regexp_string pattern in
      let until =
        try Str.search_forward regexp stream.contents stream.index
        with Not_found -> stream.length
      in
      let step_size = until - stream.index in
      String.sub stream.contents stream.index step_size,
      advance ~n:step_size stream

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

let rec parse ~loc s =
  let rec parse stream =
    let literal, stream = CharStream.located_span ~pattern:"%{" stream in
    if CharStream.is_empty stream then
      [Literal literal.txt]
    else
      let stream = CharStream.advance ~n:2 stream in
      let antiquotation, stream = CharStream.located_span ~pattern:"}" stream in
      if CharStream.is_empty stream then
        let error = make_error ~loc:antiquotation.loc "Unclosed antiquotation: %S" antiquotation.txt in
        [Literal literal.txt; Antiquoted error]
      else
        let stream = CharStream.advance ~n:1 stream in
        let expr = parse_expression antiquotation.txt ~loc:antiquotation.loc in
        Literal literal.txt :: Antiquoted expr :: parse stream
  in
  parse (CharStream.of_string s ~loc)

let extract_expressions fragments =
  let rec process fragments next_id =
    match fragments with
    | [] -> [], ""
    | Literal l :: rest ->
       let bindings, string = process rest next_id in
       bindings, l ^ string
    | Antiquoted e :: rest ->
       let bindings, string = process rest (next_id + 1) in
       let name = Format.sprintf "_%d" next_id in
       (name, e) :: bindings, "%{" ^ name ^ "}" ^ string
  in process fragments 0
