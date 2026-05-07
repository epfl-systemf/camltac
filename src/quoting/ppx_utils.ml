(** Utility methods for manipulation PPX expressions and locations. *)

let loc_of_rocq_loc (loc: Loc.t) =
  let open Loc in
  let fname =
    match loc.fname with
    | InFile { file } -> file
    | ToplevelInput -> "_toplevel_"
  in
  let loc_start = Lexing.{
    pos_fname = fname;
    pos_lnum = loc.line_nb;
    pos_bol = loc.bol_pos;
    pos_cnum = loc.bp
  }
  in
  let loc_end = Lexing.{
    pos_fname = fname;
    pos_lnum = loc.line_nb_last;
    pos_bol = loc.bol_pos_last;
    pos_cnum = loc.ep
  }
  in Ppxlib.Location.{ loc_start; loc_end; loc_ghost = false }

let rocq_loc_of_loc loc =
  let open Ppxlib in
  let Location.{ loc_start; loc_end } = loc in
  let file         = Ast_builder.Default.estring ~loc loc_start.pos_fname in
  let line_nb      = Ast_builder.Default.eint ~loc loc_start.pos_lnum in
  let line_nb_last = Ast_builder.Default.eint ~loc loc_end.pos_lnum in
  let bol_pos      = Ast_builder.Default.eint ~loc loc_start.pos_bol in
  let bol_pos_last = Ast_builder.Default.eint ~loc loc_end.pos_bol in
  let bp           = Ast_builder.Default.eint ~loc loc_start.pos_cnum in
  let ep           = Ast_builder.Default.eint ~loc loc_end.pos_cnum in
  [%expr
    Loc.{ fname    = InFile { dirpath = None; file = [%e file] };
      line_nb      = [%e line_nb];
      line_nb_last = [%e line_nb_last];
      bol_pos      = [%e bol_pos];
      bol_pos_last = [%e bol_pos_last];
      bp           = [%e bp];
      ep           = [%e ep];
    }
  ]

open Ppxlib
open Expansion_helpers

let with_let_bindings ~loc bindings expr =
  let quoter = Quoter.create () in
  let rec with_let_bindings = function
    | [] -> expr
    | (name, binding) :: rest ->
       let expr = with_let_bindings rest in
       let name = Ast_builder.Default.ppat_var ~loc:name.loc name in
       let binding = Quoter.quote quoter binding in
       [%expr let [%p name] = [%e binding] in [%e expr]]
  in
  Quoter.sanitize quoter (with_let_bindings bindings)
