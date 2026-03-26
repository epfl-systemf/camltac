(** Methods for constructing scaffolds over a snippet. *)

(** A scaffold is divided into 3 separate regions:

    - The header contains setup code that is run before the snippet.
      This includes [open] directives.

    - The main content is the part that is entered by the user.

    - The footer contains finalization code, in particular registering the
      output of the snippet and exposing APIs that were marked for export. *)
type t = {
    header: string;
    content: string;
    footer: string
}

(** Add a line number directive to the start of the given code snippet.

    A line number directive is of the form #<line>"<source_file>",
    and is used by preprocessors to map line numbers in generated code
    to their original locations.

    @see <https://ocaml.org/manual/5.4/lex.html#sss:lex-linedir> *)
let add_line_number_directive ~line_number ~source_file code =
  Format.sprintf {|# %d "%s"|} line_number source_file
  ^ "\n"
  ^ code

(** Pad the initial line of the code with whitespace to obtain
    correct error message locations. *)
let pad_initial_line ~start_col code =
  String.make start_col ' ' ^ code

let make ?loc snippet =
  let open Loc in
  match loc with
  | None -> { header = ""; content = snippet; footer = "" }
  | Some loc ->
     let start_line = loc.line_nb in
     let start_col = loc.bp - loc.bol_pos in
     let source_file =
       match loc.fname with
       | Loc.ToplevelInput -> "Toplevel"
       | Loc.InFile { file } -> file
     in
     let snippet =
       snippet
       |> pad_initial_line ~start_col
       |> add_line_number_directive
            ~line_number:start_line
            ~source_file
     in
     { header = ""; content = snippet; footer = "" }

(** [join s1 s2] appends [s2] to [s1] with a new line in-between if [s1]
    does not already end with a newline. *)
let join s1 s2 =
  if String.ends_with ~suffix:"\n" s1 then s1 ^ s2
  else s1 ^ "\n" ^ s2
    
let wrap ~before ~after { header; content; footer } = 
  { header = join header before;
    content;
    footer = join after footer }

let contents { header; content; footer } =
  let scaffold_name = "<scaffold>" in
  (* Insert a line directive for the header *)
  let header = add_line_number_directive ~line_number:1 ~source_file:scaffold_name header in
  (* Insert a line directive for the footer. *)
  let header_and_content = join header content in
  let line_count = String.fold_left (fun count c -> if c = '\n' then count + 1 else count) 1 header_and_content in
  let footer = add_line_number_directive ~line_number:line_count ~source_file:scaffold_name footer in
  join header_and_content footer

