(** Representation of OCaml code snippets. *)

(** {1 Snippets} *)

type t =
  { loc: Loc.t;
    contents: string }

let make ~loc contents = { loc; contents }

let loc { loc } = loc

let contents { contents } = contents

(** {1 Scaffolds} *)

type execution_mode =
  | Run
  | Check
  | Module of (string * Loc.t)
  | Tactic_in_term

module Scaffold = struct
  type t = Buffer.t

  (** Name of the scaffold file. *)
  let scaffold_file = "_scaffold_"

  let new_line scaffold =
    Buffer.add_char scaffold '\n'

  let require_new_line scaffold =
    let length = Buffer.length scaffold in
    if length > 0 && Buffer.nth scaffold (length - 1) <> '\n' then
      new_line scaffold

  let line_count scaffold =
    1 + (Buffer.to_seq scaffold
         |> Seq.filter (fun c -> Char.equal c '\n')
         |> Seq.length)

  (** Adds a line number directive to [scaffold].

      A line number directive is of the form #<line>"<source_file>",
      and is used by preprocessors to map line numbers in generated code
      to their original locations.

      @see <https://ocaml.org/manual/5.4/lex.html#sss:lex-linedir> *)
  let add_line_number_directive ~line ~file scaffold =
    require_new_line scaffold;
    Buffer.add_string scaffold "# ";
    Buffer.add_string scaffold (string_of_int line);
    Buffer.add_string scaffold {| "|};
    Buffer.add_string scaffold file;
    Buffer.add_char scaffold '"';
    new_line scaffold

  let add_header ?header scaffold =
    match header with
    | None -> ()
    | Some header ->
       add_line_number_directive ~line:1 ~file:scaffold_file scaffold;
       Buffer.add_string scaffold header

  let indent ~n scaffold =
    for i = 1 to n do Buffer.add_char scaffold ' ' done

  let add_contents ~(loc: Loc.t) contents scaffold =
    let file =
      match loc.fname with
      | ToplevelInput ->
         (* FIXME: Obtain original file name under ProofGeneral's toplevel. *)
         "_toplevel_"
      | InFile { file } -> file
    in
    add_line_number_directive ~line:loc.line_nb ~file scaffold;
    (* Pad the first line to obtain correct error locations. *)
    indent ~n:(loc.bp - loc.bol_pos) scaffold;
    Buffer.add_string scaffold contents

  let add_footer ?footer scaffold =
    match footer with
    | None -> ()
    | Some footer ->
       require_new_line scaffold;
       let line = line_count scaffold in
       add_line_number_directive ~line ~file:scaffold_file scaffold;
       Buffer.add_string scaffold footer

  let make ?header ?footer { loc; contents } =
    (* Estimate approx. final buffer size to avoid most allocations. *)
    let scaffold = Buffer.create (String.length contents + 256) in
    add_header ?header scaffold;
    add_contents ~loc contents scaffold;
    add_footer ?footer scaffold;
    Buffer.contents scaffold

end

let scaffold mode snippet =
  let header, footer =
    match mode with
  | Check ->
     Some "let (-) = begin", Some "end"
  | Tactic_in_term ->
     Some "let t : unit tactic =", Some "in Runtime.Output.set_tactic t"
  | Run | Module _ ->
     None, None
  in
  Scaffold.make ?header ?footer snippet
