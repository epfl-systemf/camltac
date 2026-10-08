(** Representation of OCaml snippets. *)

(** {1 Snippets} *)

(** A snippet is a string of OCaml code that is inside a Rocq file,
    obtained through the [ocaml:(…)] quotation. *)

type t
(** Type of OCaml snippets. *)

val make : loc:Loc.t -> string -> t
(** [make ~loc contents] creates a snippet with the given contents. *)

val of_file : loc:Loc.t -> string -> t
(** [of_file ~loc filename] creates a snippet for the given file. *)

val loc : t -> Loc.t
(** [loc snippet] returns the location of the snippet. *)

val contents : t -> string
(** [contents snippet] returns the contents of the snippet. *)

(** {1 Execution mode} *)

(* TODO: Move to a different file. *)

(** Execution mode of a snippet, determining how a snippet should be
    interpreted. *)
type execution_mode =
  | Eval
  (** Evaluation of OCaml tactics: [Camltac Eval ocaml:(…)]. *)

  | Check_expression
  (** Type-checking OCaml expressions: [Camltac Check ocaml:(…)]. *)

  | Check_module
  (** Type-checking OCaml modules: [Camltac Check M]. *)

  | Module of camltac_module
  (** OCaml top-level declarations: [Camltac Module M := ocaml:(…)] or
      [Camltac Run] if [name] is [None]). *)

  | Tactic_in_term
  (** Tactic-in-term modality: [Definition x := ocaml:(…)]. *)

  | Tactic_in_Ltac
  (** Tactic-in-Ltac modality: [Ltac f := ocaml:(…)]. *)

  | Tactic_in_Ltac2
  (** Tactic-in-Ltac2 modality: [Ltac2 f () := ocaml:(…)]. *)

and camltac_module =
  { name: (string * Loc.t) option; (** Name of the module, or [None] for [Camltac Run]. *)
    locality: Libobject.locality   (** Locality of the module. *)
  }
