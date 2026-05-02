(** Utility methods for manipulation PPX expressions and locations. *)

open Ppxlib

let rec expr_of_list ~loc = function
  | [] -> [%expr []]
  | head :: tail ->
     let tail_expr = expr_of_list ~loc tail in
     [%expr [%e head] :: [%e tail_expr]]
