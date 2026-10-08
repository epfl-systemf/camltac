(** Entry point for Camltac vernacular commands. *)

(** {1 Commands} *)

(** A Camltac command. *)
type t =
  | Eval
  (** Evaluation of OCaml tactics: [Camltac Eval ocaml:(…)]. *)

  | Check_expression
  (** Type-checking OCaml expressions: [Camltac Check ocaml:(…)]. *)

  | Check_module
  (** Type-checking OCaml modules: [Camltac Check M]. *)

  | Module of module_info
  (** OCaml top-level declarations: [Camltac Module M := ocaml:(…)] or
      [Camltac Run] if [name] is [None]). *)

  | Tactic_in_term
  (** Tactic-in-term modality: [Definition x := ocaml:(…)]. *)

  | Tactic_in_Ltac
  (** Tactic-in-Ltac modality: [Ltac f := ocaml:(…)]. *)

  | Tactic_in_Ltac2
  (** Tactic-in-Ltac2 modality: [Ltac2 f () := ocaml:(…)]. *)

and module_info =
  { name: (string * Loc.t) option; (** Name of the module, or [None] for [Camltac Run]. *)
    locality: Libobject.locality   (** Locality of the module. *)
  }

(** {1 Syntactic interpretation} *)

val compile_snippet : t -> Snippet.t -> Compiler.output
(** [compile_snippet cmd snippet] scaffolds and compiles [snippet] in the
    context of [cmd]. *)

(** {2 Interpretation} *)

val interpret : ?proof:Declare.Proof.t -> t -> Compiler.output -> unit
(** [interpret ?proof cmd compilation_output] interprets the compilation output
    according to [cmd].

    If [proof] is specified, interpretation is done in the context of the given proof.
 *)
