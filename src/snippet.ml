(** Representation of OCaml code snippets. *)

(** {1 Snippets} *)

type t =
  { loc: Loc.t;
    contents: string }

(** {2 Constructors} *)

let make ~loc contents = { loc; contents }

let read_file ~loc filename =
  try File.read filename
  with File.Not_found ->
    CErrors.user_err ~loc (Pp.(str "File " ++ str filename ++ str " does not exist."))

let of_file ~loc filename =
  let contents = read_file ~loc filename in
  let loc = Loc.{
     fname = InFile { dirpath = None; file = filename };
     line_nb = 1;
     bol_pos = 0;
     bp = 0;
     (* These end locations are obviously wrong, but we don't use this information. *)
     line_nb_last = max_int;
     bol_pos_last = max_int;
     ep = String.length contents
  } in
  make ~loc contents

(** {2 Getters} *)

let loc { loc; _ } = loc

let contents { contents; _ } = contents

(** {2 Subsnippets} *)

(** Position of the beginning of [line] in the Rocq file. *)
let beginning_of_line ~line { loc; contents } =
  let n = line - loc.line_nb in
  if n = 0 then
    loc.bol_pos
  else
    let rec find i n =
      match String.index_from_opt contents i '\n' with
      | None -> loc.ep
      | Some j when n = 1 -> loc.bp + j + 1
      | Some j -> find (j + 1) (n - 1)
    in
    find 0 n

(** Position of the end of the line starting at [bol]. *)
let end_of_line ~bol { contents; loc } =
  (* Note: [bol < loc.bp] for the first line. *)
  let from = (max bol loc.bp) - loc.bp in
  match String.index_from_opt contents from '\n' with
  | Some i -> loc.bp + i
  | None -> loc.ep

let clamp x ~low ~high = max low (min high x)

let sub ~lines:(line_nb, line_nb_last) ~chars:(char1, char2) ({ loc; contents } as snippet) =
  let bol_pos = beginning_of_line ~line:line_nb snippet in
  let bol_pos_last = beginning_of_line ~line:line_nb_last snippet in
  let bp =
    clamp (bol_pos + char1)
      ~low:bol_pos
      ~high:(end_of_line ~bol:bol_pos snippet)
  in
  let ep =
    clamp (bol_pos_last + char2)
      ~low:bol_pos_last
      ~high:(end_of_line ~bol:bol_pos_last snippet)
  in
  let contents = String.sub contents (bp - loc.bp) (ep - bp) in
  let loc = { loc with line_nb; line_nb_last; bol_pos; bol_pos_last; bp; ep } in
  make ~loc contents
