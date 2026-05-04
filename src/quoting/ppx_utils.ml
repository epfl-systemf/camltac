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

let rocq_loc_of_loc loc: Loc.t =
  let Ppxlib.Location.{ loc_start; loc_end } = loc in
  { fname        = InFile { dirpath = None; file = loc_start.pos_fname };
    line_nb      = loc_start.pos_lnum;
    line_nb_last = loc_end.pos_lnum;
    bol_pos      = loc_start.pos_bol;
    bol_pos_last = loc_end.pos_bol;
    bp           = loc_start.pos_cnum;
    ep           = loc_end.pos_cnum;
  }

open Ppxlib
open Expansion_helpers

let rec expr_of_list ~loc = function
  | [] -> [%expr []]
  | head :: tail ->
     let tail_expr = expr_of_list ~loc tail in
     [%expr [%e head] :: [%e tail_expr]]

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
