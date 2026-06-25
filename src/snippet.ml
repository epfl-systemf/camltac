(** Representation of OCaml code snippets. *)

(** {1 Snippets} *)

type t =
  { loc: Loc.t;
    contents: string }

let make ~loc contents = { loc; contents }

let read_file ~loc filename =
  if Sys.file_exists filename then
    let in_channel = open_in filename in
    let contents = In_channel.input_all in_channel in
    In_channel.close_noerr in_channel;
    contents
  else
    CErrors.user_err ~loc (Pp.fmt "File %S does not exist." filename)

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
     ep = max_int
  } in
  make ~loc contents

let loc { loc } = loc

let contents { contents } = contents

(** {1 Scaffolds} *)

type execution_mode =
  | Run
  | Eval of string
  | Check
  | Module of { name: string; loc: Loc.t; local: bool option }
  | Tactic_in_term
  | Tactic_in_Ltac
  | Tactic_in_Ltac2

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
    | Eval typ ->
       Some ({|[@@@using "ppx_deriving.runtime"]
              [@@@ppx "ppx_deriving.show"]
              open Api.Printers
              type t = |} ^ typ ^ {|[@@deriving show]
              let () = Runtime.Output.set_tactic begin
                let* x =|}),
       Some "in (return (show x)) end"
    | Tactic_in_term | Tactic_in_Ltac | Tactic_in_Ltac2 ->
       Some "let t : unit tactic =", Some "in Runtime.Output.set_tactic t"
    | Run | Module _ ->
       None, None
  in
  Scaffold.make ?header ?footer snippet
