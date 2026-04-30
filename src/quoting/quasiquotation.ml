open Ppxlib

type fragment =
| Literal of string
| Antiquoted of expression

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

let generate_template fragments =
  let rec process fragments next_id =
    match fragments with
    | [] -> "", []
    | Literal l :: rest ->
       let template, bindings = process rest next_id in
       l ^ template, bindings
    | Antiquoted e :: rest ->
       let template, bindings = process rest (next_id + 1) in
       let name = Format.sprintf "_%d" next_id in
       "%{" ^ name ^ "}" ^ template, (name, e) :: bindings
  in process fragments 0
