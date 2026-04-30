open Ppxlib

(** Kinds of antiquotations. *)
type antiquotation_kind =
  | Unspecified (** {v %{…} v} *)
  | Constr      (** {v %constr:{…} v} *)
  | Preterm     (** {v %preterm:{…} v} *)
  | Expr        (** {v %expr:{…} v} *)

(** Types of quasiquotations fragments. *)
type fragment =
  | Literal of string
    (** A literal string inside the quasiquotation. *)

  | Antiquoted of antiquotation_kind * expression
    (** An antiquoted expression inside the quasiquotation. *)

val parse : loc:location -> string -> fragment list
(** [parse ~loc s] parses the quasiquotation [s] by finding all antiquotations
    (of the form {v %{…} v} or {v %kind:{…} v}) in [s].

    Currently, the implementation does not allow the "}" character to appear inside
    an antiquotation. *)

val generate_template : fragment list -> string * (string * expression * antiquotation_kind) list
(** [generate_template fragments] creates a template string with a list of
    bindings from the list of fragments by assigning a synthetic name to
    each antiquoted expression.

    For example, [generate_template [Literal "1 + "; Antiquoted (Expr, .)]]
    returns the template string ["1 + %{_0}"] along with the list [[("_0", ., Expr)]].
    Note that the returned template simplifies all antiquotations to use the
    format {v %{…} v}, which is simpler for Rocq's parser to recognize.
 *)
