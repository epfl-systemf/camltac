(** Snippet scaffolding. *)

open Names

(** {1 Scaffolds} *)

type mode =
  | Infer_type
  | Tactic
  | Show_tactic of { typ: string }
  | Plain

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
  Buffer.add_string scaffold (String.escaped file);
  Buffer.add_char scaffold '"';
  new_line scaffold

let module_aliases_format : _ format =
  {|
open struct
  [%@%@%@warning "-60"]
  %s
end
;;
|}

let module_aliases () =
  match Compile_context.module_aliases () with
  | [] -> None
  | aliases ->
     let contents =
       List.map (fun (name, mangled) -> Format.sprintf "module %s = %s" name mangled) aliases
       |> String.concat "\n  "
       |> Format.sprintf module_aliases_format
     in Some contents

let add_module_aliases scaffold =
  match module_aliases () with
  | None -> ()
  | Some aliases ->
     add_line_number_directive ~line:1 ~file:scaffold_file scaffold;
     Buffer.add_string scaffold aliases

let add_part ?part scaffold =
  match part with
  | None -> ()
  | Some part ->
     require_new_line scaffold;
     let line = line_count scaffold in
     add_line_number_directive ~line ~file:scaffold_file scaffold;
     Buffer.add_string scaffold part

let indent ~n scaffold =
  for _ = 1 to n do Buffer.add_char scaffold ' ' done

let add_contents ~(loc: Loc.t) contents scaffold =
  let file =
    match loc.fname with
    | InFile { file; _ } -> file
    | ToplevelInput ->
       (* Use the module name set by the [-top] option, if any. *)
       let _, top_module_name = Libnames.split_dirpath (Lib.library_dp ()) in
       match Id.to_string top_module_name with
       | "Top" (* default *) -> "_toplevel_"
       | name -> name ^ ".v"
  in
  add_line_number_directive ~line:loc.line_nb ~file scaffold;
  (* Pad the first line to obtain correct error locations. *)
  indent ~n:(loc.bp - loc.bol_pos) scaffold;
  Buffer.add_string scaffold contents

let make ~loc ?header ?footer contents =
  (* Estimate approx. final buffer size to avoid most allocations. *)
  let scaffold = Buffer.create (String.length contents + 256) in
  add_module_aliases scaffold;
  add_part ?part:header scaffold;
  add_contents ~loc contents scaffold;
  add_part ?part:footer scaffold;
  Buffer.contents scaffold

let header_footer = function
  | Infer_type ->
     Some ("let " ^ Interface.single_value_name ^ " = begin"), Some "end"
  | Show_tactic { typ } ->
     Some ({|open Api.Printers
            type t = |} ^ typ ^ {|[@@deriving show]
                                 let () = Runtime.Output.set_tactic begin
                                 let* x =|}),
     Some ({|in (return (Pp.(str "- : " ++ str "|} ^ typ ^ {|" ++ spc () ++ str "=" ++ spc () ++ str (show x)))) end|})
  | Tactic ->
     Some "let t : unit tactic =", Some "in Runtime.Output.set_tactic t"
  | Plain ->
     None, None

let make mode snippet =
  let loc = Snippet.loc snippet in
  let contents = Snippet.contents snippet in
  let header, footer = header_footer mode in
  make ~loc ?header ?footer contents
