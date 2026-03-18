open Pp

let run_file file =
  match Compiler.compile file with
  | Ok out ->
     Loader.load_file out;
     Sys.remove out
  | Error err ->
     CErrors.user_err (fmt "Compilation of %s exited with error code %d." file err)

(** Prepend line number directives to each line of the snippet.

    A line number directive is of the form #<line>"<source_file>",
    and is used by preprocessors to map line numbers in generated code
    to their original locations.

    See https://ocaml.org/manual/5.4/lex.html#sss:lex-linedir. *)
let prepend_line_number_directives loc snippet =
  let open Loc in
  let start_line = loc.line_nb in
  let start_col = loc.bp - loc.bol_pos in
  let source_file = 
    match loc.fname with
    | Loc.ToplevelInput -> "Toplevel"
    | Loc.InFile { file } -> file
  in
  (* To make column numbers match, we have to pad the first line *)
  let initial_padding = String.make start_col ' ' in
  Format.sprintf {|# %d "%s"|} start_line source_file
  ^ "\n"
  ^ initial_padding
  ^ snippet

let run_snippet ~loc snippet =
  let snippet = prepend_line_number_directives loc snippet in
  Temp_file.with_temp_file ~prefix:"snippet" ~suffix:".ml" snippet begin fun temp_file ->
    match Compiler.compile temp_file with
    | Ok out ->
       Loader.load_file out;
       Sys.remove out
    | Error err ->
       CErrors.user_err (fmt "Compilation of snippet exited with error code %d." err)
  end

let run_snippet_as_term ~loc snippet =
  let snippet = prepend_line_number_directives loc snippet in
  let snippet = "let res = \n" ^ snippet ^ "\n in Registry.out := Some res" in
  Temp_file.with_temp_file ~prefix:"snippet" ~suffix:".ml" snippet begin fun temp_file ->
    match Compiler.compile temp_file with
    | Ok out ->
       Loader.load_file out;
       Sys.remove out
    | Error err ->
       CErrors.user_err (fmt "Compilation of snippet exited with error code %d." err)
  end;
  Option.get !Registry.out
