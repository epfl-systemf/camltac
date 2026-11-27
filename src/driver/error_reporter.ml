(** Error reporting. *)

open Camltac_workspace
open Camltac_toolchain

(** {1 Locations}

    We convert compiler locations to Rocq {!Loc.t} by computing the position of
    the characters, using the snippet's location as a basis. *)

(** Position of the beginning of [line] in the Rocq file. *)
let beginning_of_line ~line source =
  let loc = Snippet.loc source in
  let n = line - loc.line_nb in
  if n = 0 then
    loc.bol_pos
  else
    let rec find i n =
      match String.index_from_opt (Snippet.contents source) i '\n' with
      | None              -> loc.ep
      | Some j when n = 1 -> loc.bp + j + 1
      | Some j            -> find (j + 1) (n - 1)
    in
    find 0 n

(** Position of the end of the line starting at [bol]. *)
let end_of_line ~bol source =
  let loc = Snippet.loc source in
  (* Note: [bol < loc.bp] for the first line. *)
  let from = (max bol loc.bp) - loc.bp in
  match String.index_from_opt (Snippet.contents source) from '\n' with
  | Some i -> loc.bp + i
  | None   -> loc.ep

let clamp x ~low ~high = max low (min high x)

let line_loc ~line source =
  let bol_pos      = beginning_of_line ~line source in
  let bol_pos_last = beginning_of_line ~line:(line + 1) source in
  { (Snippet.loc source) with
    line_nb = line;
    line_nb_last = line + 1;
    bol_pos;
    bp = bol_pos;
    bol_pos_last;
    ep = bol_pos_last
  }

let range_loc ~lines:(line_nb, line_nb_last) ~chars:(char1, char2) source =
  let bol_pos      = beginning_of_line ~line:line_nb source in
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
  | Diagnostic.File file         -> Snippet.loc source
  | Line { file; line }          -> line_loc ~line source
  | Range { file; lines; chars } -> range_loc ~lines ~chars source

(** {1 Error reporting} *)

let report ~source Diagnostic.{ loc; severity; message } =
  let loc = Option.map (to_loc ~source) loc in
  match severity with
  | Unknown   -> Feedback.msg_notice ?loc message
  | Warning _ -> Feedback.msg_warning ?loc message
  | Error     -> CErrors.user_err ?loc message

let report_all ~source diagnostics =
  (* TODO: Print all errors at once? *)
  List.iter (report ~source) diagnostics
