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

val generate_template : fragment list -> string * (string * expression) list
(** [generate_template fragments] creates a template string with a list of
    bindings from the list of fragments by assigning a synthetic name to
    each antiquoted expression.

    For example, [generate_template [Literal "1 + "; Antiquoted [%expr x]]]
    returns the template string ["1 + %{_0}"] along with the list [[("_0", x)]]. *)
