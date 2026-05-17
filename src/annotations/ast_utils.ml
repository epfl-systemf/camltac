(** Collection of reusable AST patterns. *)

open Ppxlib
open Ast_pattern

(** [comma_separated p] accepts a comma-separated list of [p].

    For example, if [p = estring __], then [comma_separated p]
    accepts ["foo"] as well as ["bar", "baz"]. *)
let comma_separated p =
  alt
    (p |> map ~f:(fun f expr -> f [expr]))
    (pexp_tuple (many p))
