open Ppxlib

(** Types of quasiquotations fragments. *)
type fragment =
  | Literal of string        (** A literal string inside the quasiquotation. *)
  | Antiquoted of expression (** An antiquoted expression inside the quasiquotation. *)

val parse : loc:location -> string -> fragment list
(** [parse ~loc s] parses the quasiquotation [s] by finding all occurences of {v
    %{…} v} in [s].

    Currently, the implementation does not allow the "}" character to appear inside
    an antiquotation. *)

val extract_expressions : fragment list -> (string * expression) list * string
(** [extract_expressions fragments] returns the list of antiquoted expressions
    with synthetic names, as well as the string where every antiquoted
    expression is replaced by the variable name.

    For example, [extract_expressions [Literal "1 + "; Antiquoted [%expr x]]] yields
    the list [[("_0", x)]] along with the string ["1 + %{_0}"]. *)
