(** Parsing of OCaml compiler diagnostics. *)

open Camltac_workspace

(** {1 Diagnostic} *)

type t =
  { loc      : location option;
    severity : severity;
    message  : Pp.t;
  }

and location =
  | File of string
  | Line of { file : string; line : int }
  | Range of { file : string; lines : int * int; chars : int * int }

and severity =
  | Warning of int
  | Error
  | Unknown

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

(** {2 Severity}

    Severity is included on the second line of the diagnostic. *)

let parse_severity =
  try_parse "Error" Error <+>
  try_parse "Warning %d" (fun n -> Warning n)

let parse_severity_line line =
  match parse_severity line with
  | Some severity ->
     let message =
       match String.index_opt line ':' with
       | Some i -> String.sub line (i + 2) (String.length line - i - 2)
       | None   -> line
     in
     severity, Pp.str message
  | None -> Unknown, Pp.str line

(** {2 Message} *)

let continuation_indent = function
  | Error     -> 7
  | Warning _ -> 2
  | Unknown   -> 0

let parse_message_line ~severity line =
  let indent = continuation_indent severity in
  String.sub line indent (String.length line - indent)

let rec parse_message ~severity = function
  | [] -> Pp.mt (), []
  | line :: rest ->
     if is_header line then Pp.mt (), line :: rest
     else
       let message, rest = parse_message ~severity rest in
       let line = parse_message_line ~severity line in
       Pp.(str line ++ fnl () ++ message), rest

(** {2 Main method} *)

let rec parse_lines = function
  | [] -> []
  | [header] ->
     (* A single empty message. *)
     let loc = parse_header header in
     [{ loc; severity = Unknown; message = Pp.mt () }]
  | header :: severity_line :: rest ->
     match parse_header header with
     | Some loc ->
        let severity, first_line = parse_severity_line severity_line in
        let continuation, rest = parse_message ~severity rest in
        let message = Pp.(first_line ++ fnl () ++ continuation) in
        { loc = Some loc; severity; message } :: parse_lines rest
     | None ->
        (* Standalone message. *)
        let severity = Unknown in
        let message, rest = parse_message ~severity (severity_line :: rest) in
        { loc = None; severity; message } :: parse_lines rest

let parse stderr =
  In_channel.input_all stderr
  |> String.split_on_char '\n'
  |> List.filter_map (fun line -> if String.trim line = "" then None else Some line)
  |> parse_lines
