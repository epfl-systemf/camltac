(** Support for tactic-in-terms using Rocq's generic argument mecanism. *)

open Names

(** Raw representation of OCaml code snippets.
    The OCaml code may contain reference to unbound variables. *)
type raw_ocaml = Snippet.t

(** Globalized representation of OCaml code snippets.
    Each name is mapped to a globalized term used for interpretation. *)
type glob_ocaml =
  { env: Runtime.Environment.t;
    snippet: raw_ocaml }

(** Tag for OCaml-in-term terms. *)
val wit_ocaml_in_term : (raw_ocaml, glob_ocaml) GenConstr.tag
