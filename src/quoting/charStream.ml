open Ppxlib

type t =
  { contents: string; (** Contents of the stream. *)
    pos: position;    (** Current position of the stream inside the file. *)
    index: int;       (** Index of the current position in the stream contents. *)
    length: int;      (** Length of the stream. *)
  }

let of_string ~loc contents =
  { contents;
    pos = loc.loc_start;
    index = 0;
    length = String.length contents;
  }

let is_empty stream =
  stream.index >= stream.length

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

let take ~n stream =
  assert (n >= 0);
  if is_empty stream then ""
  else String.sub stream.contents stream.index n

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
