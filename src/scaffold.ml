(** Scaffolding snippets. *)

(** {1 Scaffolding} *)

type kind =
  | Expression
  | Module of { name: string option }
  | Unit_tactic
  | Value_tactic of { typ: string }

(** File name used for segments added by the scaffold. *)
let scaffold_file = "_scaffold_"

(** A line number directive is of the form [# <line> "<source_file>"] used by
    preprocessors to map line numbers in generated code to their original
    positions.

    @see <https://ocaml.org/manual/5.4/lex.html#sss:lex-linedir> *)
let line_number_directive ~line ~file =
  Format.sprintf {|# %d "%s"|} line (String.escaped file)

(** {2 Buffer}

    We use a {!Buffer.t} to build the scaffold incrementally. *)

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

let add_line_number_directive ~line ~file scaffold =
  require_new_line scaffold;
  Buffer.add_string scaffold (line_number_directive ~line ~file);
  new_line scaffold

let add_nonempty_segment ~segment scaffold =
  require_new_line scaffold;
  let line = line_count scaffold in
  add_line_number_directive ~line ~file:scaffold_file scaffold;
  Buffer.add_string scaffold segment

let add_segment ~segment scaffold =
  let segment = String.trim segment in
  if segment <> "" then add_nonempty_segment ~segment scaffold

let indent ~n scaffold =
  for _ = 1 to n do Buffer.add_char scaffold ' ' done

let file_of_loc (loc: Loc.t) =
  match loc.fname with
  | InFile { file; _ } -> file
  | ToplevelInput ->
     (* Use the module name set by the [-top] option, if any. *)
     let _, top_module_name = Libnames.split_dirpath (Lib.library_dp ()) in
     match Names.Id.to_string top_module_name with
     | "Top" (* default *) -> "_toplevel_"
     | name -> name ^ ".v"

let add_contents ~loc contents scaffold =
  add_line_number_directive ~line:loc.Loc.line_nb ~file:(file_of_loc loc) scaffold;
  (* Indent the first line to obtain correct column numbers. *)
  indent ~n:(loc.bp - loc.bol_pos) scaffold;
  Buffer.add_string scaffold contents

let module_aliases_format : _ format =
  {|
open struct
  [%@%@%@ocaml.warning "-60"]
  %s
end
;;
|}

let module_aliases () =
  match Compile_context.module_aliases () with
  | [] -> ""
  | aliases ->
     List.map (fun (name, mangled) -> Format.sprintf "module %s = %s" name mangled) aliases
     |> String.concat "\n  "
     |> Format.sprintf module_aliases_format

let build_scaffold ~loc ~header ~footer contents =
  let scaffold = Buffer.create (String.length contents) in
  add_segment ~segment:(module_aliases ()) scaffold;
  add_segment ~segment:header scaffold;
  add_contents ~loc contents scaffold;
  add_segment ~segment:footer scaffold;
  Buffer.contents scaffold

(** {2 Scaffolds} *)

let expression_scaffold =
  Format.sprintf {|let %s = begin|} Interface.single_value_name, {|end|}

let module_scaffold name =
  {|
open struct
  module Make () = struct
    |}, Format.sprintf {|
  end
end

let () = Runtime.Output.register_module %S
  (fun () -> let module _ = Make () in ())

include Make ()|} name

let unit_tactic_scaffold =
  {|let t : unit tactic = begin|}, {|end in Runtime.Output.set_tactic t|}

let value_tactic_scaffold typ =
  {|
let () = Runtime.Output.set_tactic begin
  let* x = begin
    |}, Format.sprintf {|
  end in
  let* env = Tactic.env in
  let* sigma = Tactic.sigma in
  let open Api.Printers.Env_printers(struct
    let env = env
    let sigma = sigma
  end) in
  let open struct type t = %s [%@%@deriving show] end in
  return (Pp.(str "- : " ++ str %S ++ spc ()
           ++ str "=" ++ spc () ++ str (show x)))
end
|} typ typ

let make kind snippet =
  let header, footer =
    match kind with
    | Expression                  -> expression_scaffold
    | Module { name = Some name } -> module_scaffold name
    | Module { name = None }      -> "", ""
    | Unit_tactic                 -> unit_tactic_scaffold
    | Value_tactic { typ }        -> value_tactic_scaffold typ
  in
  let loc = Snippet.loc snippet in
  let contents = Snippet.contents snippet in
  build_scaffold ~loc ~header ~footer contents
