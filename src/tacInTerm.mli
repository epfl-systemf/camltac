(** Support for tactic-in-terms using Rocq's generic argument mecanism. *)

open Names

(** Representation of OCaml snippets in [Constrexpr.constr_expr] terms. *)
type raw_ocaml

(** Representation of OCaml snippets in [Glob_term.glob_constr] terms. *)
type glob_ocaml

(** Tag for OCaml-in-term terms. *)
val wit_ocaml_in_term : (raw_ocaml, glob_ocaml) GenConstr.tag
