(** Utility methods for manipulation PPX expressions and locations. *)

open Ppxlib

let rec expr_of_list ~loc = function
  | [] -> [%expr []]
  | head :: tail ->
     let tail_expr = expr_of_list ~loc tail in
     [%expr [%e head] :: [%e tail_expr]]

let rec with_let_bindings ~loc bindings expr =
  match bindings with
  | [] -> expr
  | (name, binding) :: rest ->
     let expr = with_let_bindings ~loc rest expr in
     let name = Ast_builder.Default.ppat_var ~loc:name.loc name in
     [%expr let [%p name] = [%e binding] in [%e expr]]
