(** Representation of OCaml snippets. *)

(** {1 Snippets} *)

(** A snippet is a string of OCaml code that is inside a Rocq file,
    obtained through the [ocaml:(…)] quotation. *)

type t
(** Type of OCaml snippets. *)

val make : loc:Loc.t -> string -> t
(** [make ~loc contents] creates a snippet with the given contents. *)

val loc : t -> Loc.t
(** [loc snippet] returns the location of the snippet. *)

val contents : t -> string
(** [contents snippet] returns the contents of the snippet. *)

(** {1 Scaffolds} *)

(** A scaffold is a temporary file used for compiling snippets. Its content
    depends on the expected execution mode of the snippet, i.e., how the snippet
    should be interpreted.

    For example, tactic-in-term snippets should be of type [constr tactic], and
    this constraint is expressed by scaffolding the snippet as
    [let res : constr tactic = <snippet> in res]. *)

(** Execution mode of a snippet, determining how a snippet should be
    interpreted. *)
type execution_mode =
  | Run                        (** OCaml code that is run for its side-effects ([Camltac Run ocaml:(…)]). *)
  | Module of (string * Loc.t) (** OCaml top-level declarations ([Camltac Module M := ocaml:(…)]). *)
  | Tactic_in_term             (** Tactic-in-term modality (e.g. [Definition x := ocaml:(…)]). *)

val scaffold : execution_mode -> t -> string
(** [scaffold mode snippet] returns the contents of the scaffold file for the
    given [snippet], assuming [mode] is the execution mode. *)
