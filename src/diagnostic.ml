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

let to_loc ~source = function
  | File file -> Snippet.loc source
  | Line { file; line } ->
     Snippet.loc (Snippet.sub ~lines:(line, line + 1) ~chars:(0, max_int) source)
  | Range { file; lines = (line1, line2); chars = (char1, char2) } ->
     Snippet.loc (Snippet.sub ~lines:(line1, line2) ~chars:(char1, char2) source)

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
