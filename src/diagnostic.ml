(** Parsing of OCaml compiler diagnostics. *)

(** {1 Diagnostic} *)

type severity =
  | Alert of string
  | Warning of int
  | Error
  | Unknown

type t =
  { loc      : Loc.t option;
    severity : severity;
    message  : Pp.t;
  }


(** {2 Compiler locations} *)

(** Locations as printed by the OCaml compiler. Lines are 1-based, characters
    are 0-based offsets within their line. *)
type location =
  | File of string
  (** [File "file.ml":] *)

  | Line of { file : string; line : int }
  (** [File "file.ml", line l:] *)

  | Range of { file : string; lines : int * int; chars : int * int }
  (** [File "file.ml", lines l1-l2, characters c1-c2:] *)

(** {1 Parsing} *)

(** {2 Combinators} *)

let try_parse fmt k line =
  try Some (Scanf.sscanf line fmt k)
  with Scanf.Scan_failure _ | Failure _ | End_of_file -> None

let (<+>) f g = fun line ->
  match f line with
  | (Some _) as x -> x
  | None -> g line

(** {2 Header}

    The header of a diagnostic is a single line that shows the location of the error.
    It usually takes the form of [File "file.ml", lines 1-2, characters 1-2:], with
    slight variations possible.
 *)

let parse_header =
  let range file line1 line2 char1 char2 =
    Range { file; lines = (line1, line2); chars = (char1, char2) }
  in
  try_parse "File %S:" (fun file -> File file) <+>
  try_parse "File %S, line %d:" (fun file line -> Line { file; line }) <+>
  try_parse "File %S, line %d, character %d:" (fun file line c -> range file line line c c) <+>
  try_parse "File %S, line %d, characters %d-%d:" (fun file line c1 c2 -> range file line line c1 c2) <+>
  try_parse "File %S, lines %d-%d, characters %d-%d:" (fun file line1 line2 c1 c2 -> range file line1 line2 c1 c2)

let is_header line =
  parse_header line <> None

(** {2 Locations}

    We convert compiler locations to Rocq {!Loc.t} by computing the position
    of the characters, using the snippet's location as a basis. *)

(** Position of the beginning of [line] in the Rocq file. *)
let beginning_of_line ~line source =
  let loc = Snippet.loc source in
  let n = line - loc.line_nb in
  if n = 0 then
    loc.bol_pos
  else
    let rec find i n =
      match String.index_from_opt (Snippet.contents source) i '\n' with
      | None -> loc.ep
      | Some j when n = 1 -> loc.bp + j + 1
      | Some j -> find (j + 1) (n - 1)
    in
    find 0 n

(** Position of the end of the line starting at [bol]. *)
let end_of_line ~bol source =
  let loc = Snippet.loc source in
  (* Note: [bol < loc.bp] for the first line. *)
  let from = (max bol loc.bp) - loc.bp in
  match String.index_from_opt (Snippet.contents source) from '\n' with
  | Some i -> loc.bp + i
  | None -> loc.ep

let clamp x ~low ~high = max low (min high x)

let range_loc ~lines:(line_nb, line_nb_last) ~chars:(char1, char2) source =
  let bol_pos = beginning_of_line ~line:line_nb source in
  let bol_pos_last = beginning_of_line ~line:line_nb_last source in
  let bp =
    clamp (bol_pos + char1)
      ~low:bol_pos
      ~high:(end_of_line ~bol:bol_pos source)
  in
  let ep =
    clamp (bol_pos_last + char2)
      ~low:bol_pos_last
      ~high:(end_of_line ~bol:bol_pos_last source)
  in
  { (Snippet.loc source) with line_nb; line_nb_last; bol_pos; bol_pos_last; bp; ep }

let to_loc ~source = function
  | File file -> Snippet.loc source
  | Line { file; line } ->
     range_loc ~lines:(line, line + 1) ~chars:(0, max_int) source
  | Range { file; lines = (line1, line2); chars = (char1, char2) } ->
     range_loc ~lines:(line1, line2) ~chars:(char1, char2) source

(** {2 Severity}

    Severity is included on the second line of the diagnostic. *)

let line_severity =
  try_parse "Error" Error <+>
  try_parse "Warning %d" (fun n -> Warning n) <+>
  try_parse "Alert %s:" (fun name -> Alert name)

let parse_severity lines =
  let line = try List.hd lines with Failure _ -> "" in
  let severity = line_severity line in
  match severity with
  | Some severity ->
     let indent = match String.index_opt line ':' with
       | Some i -> min (i + 2) (String.length line)
       | None -> 0
     in
     severity, indent
  | None -> Unknown, 0

(** {2 Message} *)

let rec parse_message ~indent = function
  | [] -> Pp.mt (), []
  | line :: rest ->
     if is_header line then Pp.mt (), line :: rest
     else
       let message, rest = parse_message ~indent rest in
       (* Continuation lines may be shorter than the indentation. *)
       let indent = min indent (String.length line) in
       let line = String.sub line indent (String.length line - indent) in
       Pp.(str line ++ fnl () ++ message), rest

(** {2 Main method} *)

let rec parse_lines ~source = function
  | [] -> []
  | header :: rest ->
     match parse_header header with
     | Some location ->
        let loc = Some (to_loc ~source location) in
        let severity, indent = parse_severity rest in
        let message, rest = parse_message ~indent rest in
        { loc; severity; message } :: parse_lines ~source rest
     | None ->
        (* Standalone message. *)
        let message, rest = parse_message ~indent:0 (header :: rest) in
        { loc = None; severity = Unknown; message } :: parse_lines ~source rest

let parse ~source stderr =
  In_channel.input_all stderr
  |> String.split_on_char '\n'
  |> List.filter_map (fun line -> if String.trim line = "" then None else Some line)
  |> parse_lines ~source
