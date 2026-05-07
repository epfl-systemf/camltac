open Ppxlib

(** Kinds of antiquotations. *)
type antiquotation_kind =
  | Unspecified (** [%{…}] *)
  | Constr      (** [%constr:{…}] *)
  | Preterm     (** [%preterm:{…}] *)
  | Expr        (** [%expr:{…}] *)

(** Types of quasiquotations fragments. *)
type fragment =
  | Literal of string
    (** A literal string inside the quasiquotation. *)

  | Antiquoted of antiquotation_kind * expression
    (** An antiquoted expression inside the quasiquotation. *)

val parse : loc:location -> string -> fragment list
(** [parse ~loc s] parses the quasiquotation [s] by finding all antiquotations
    (of the form [%{…}] or [%kind:{…}]) in [s].

    Currently, the implementation does not allow the [}] character to appear inside
    an antiquotation. *)

val generate_template : fragment list -> string * (expression * antiquotation_kind) list
(** [generate_template fragments] creates a template string along with a list of
    bindings from the list of fragments by assigning a natural number to each
    antiquoted expression.

    For example, [generate_template [Literal "1 + "; Antiquoted (Expr, x)]]
    returns the template string ["1 + %{0}"] along with the list [[(x, Expr)]].
    Note that the returned template simplifies all antiquotations to use the
    format [%{n}] for some natural number [n], which is very easily recognized
    by Rocq's parser.
 *)
