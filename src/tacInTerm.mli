(** Support for tactic-in-terms using Rocq's generic argument mecanism. *)

open Names

(** Raw representation of OCaml code snippets.
    The OCaml code is compiled once at parsing time to avoid unnecessary overhead on each interpretation. *)
type raw_ocaml = {
    (** Source code of the snippet, used for printing purposes. *)
    source_code: Snippet.t;

    (** Path to the compilation artifact. *)
    compiled_file: string
}

(** Globalized representation of OCaml code snippets.
    Each name is mapped to a globalized term used for interpretation. *)
type glob_ocaml =
  { env: Runtime.Environment.t;
    snippet: raw_ocaml }

(** Tag for OCaml-in-term terms. *)
val wit_ocaml_in_term : (raw_ocaml, glob_ocaml) GenConstr.tag
