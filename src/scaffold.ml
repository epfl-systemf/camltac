(** Methods for constructing scaffolds over a snippet. *)

open Snippet

(** A scaffold is divided into 3 separate regions:

    - The header contains setup code that is run before the snippet.
      This can include [open] directives, let bindings, etc.

    - The main content is the snippet that is entered by the user.

    - The footer contains finalization code, in particular registering the
      output of the snippet and exposing APIs that were marked for export. *)
type t =
  | Snippet of Snippet.t
  | Wrap of {
      before: string;
      scaffold: t;
      after: string
    }

let make snippet = Snippet snippet

(** [join s1 s2] appends [s2] to [s1] with a new line in-between if [s1]
    does not already end with a newline. *)
let join s1 s2 =
  if String.ends_with ~suffix:"\n" s1 then s1 ^ s2
  else s1 ^ "\n" ^ s2

let wrap ~before ~after scaffold =
  Wrap { before; scaffold; after }

(** Add a line number directive to the start of the given code fragment.

    A line number directive is of the form #<line>"<source_file>",
    and is used by preprocessors to map line numbers in generated code
    to their original locations.

    @see <https://ocaml.org/manual/5.4/lex.html#sss:lex-linedir> *)
let line_number_directive ~line_number ~source_file =
  Format.sprintf {|# %d "%s"|} line_number source_file ^ "\n"

let contents scaffold =
  let buffer = Buffer.create 256 in
  let scaffold_file = "_scaffold_" in
  let append s = Buffer.add_string buffer s in
  let newline () = Buffer.add_char buffer '\n' in
  let indent ~n = for i = 1 to n do Buffer.add_char buffer ' ' done in
  let require_new_line () =
    let length = Buffer.length buffer in
    if length > 0 && Buffer.nth buffer (length - 1) <> '\n' then
      newline ()
  in
  let rec append_scaffold = function
    | Snippet { loc; contents } ->
       (* Insert line directive for snippet content *)
       let source_file =
         match loc.fname with
         | Loc.ToplevelInput -> "_toplevel_"
         (* FIXME: Top-level input shouldn't really have a file name; compilation
            error messages start with [File "_toplevel_", …], which is not really
            great. *)
         (* FIXME: ProofGeneral uses the toplevel to send its command, so if we're running
            under ProofGeneral, we should use the original file name. *)
         | Loc.InFile { file } -> file
       in
       require_new_line ();
       append (line_number_directive ~line_number:(loc.line_nb) ~source_file);
       (* Pad the initial line of the code with whitespace to obtain correct
          error message locations. *)
       indent ~n:(loc.bp - loc.bol_pos);
       append contents;
       (* Insert line directive for the rest of the content. *)
       let current_line = 1 + (Buffer.to_seq buffer |> Seq.filter (fun c -> c = '\n') |> Seq.length) in
       require_new_line ();
       append (line_number_directive ~line_number:current_line ~source_file:scaffold_file)
    | Wrap { before; scaffold; after } ->
       require_new_line ();
       append before;
       require_new_line ();
       append_scaffold scaffold;
       require_new_line ();
       append after
  in
  append (line_number_directive ~line_number:1 ~source_file:scaffold_file);
  append (Dynamic_prelude.contents ());
  require_new_line ();
  append_scaffold scaffold;
  Buffer.contents buffer
