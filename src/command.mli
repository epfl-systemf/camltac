(** Entry point for Camltac vernacular commands. *)

(** {1 Commands} *)

(** The type for commands. *)
type t =
  | Eval
  (** Evaluation of OCaml tactics: [Camltac Eval ocaml:(…)]. *)

  | Check_expression
  (** Type-checking of OCaml expressions: [Camltac Check ocaml:(…)]. *)

  | Check_module
  (** Type-checking of OCaml modules: [Camltac Check M]. *)

  | Module of module_info
  (** OCaml top-level declarations: [Camltac Module M := ocaml:(…)] or
      [Camltac Run] if [name] is [None]. *)

  | Tactic_in_term
  (** Tactic-in-term modality: [Definition x := ocaml:(…)]. *)

  | Tactic_in_Ltac
  (** Tactic-in-Ltac modality: [Ltac f := ocaml:(…)]. *)

  | Tactic_in_Ltac2
  (** Tactic-in-Ltac2 modality: [Ltac2 f () := ocaml:(…)]. *)

and module_info =
  { name: (string * Loc.t) option;
    (** Name of the module, or [None] for [Camltac Run]. *)

    locality: Libobject.locality;
    (** Locality of the module. *)
  }

(** {1 Synterp} *)

(** Rocq evaluates commands in two distinct phases:

    - Syntactic interpretation, or {e synterp}, does enough to be able to parse
      the file.
    - Interpretation, or {e interp}, performs the effect of the command.

    Usually, interp is run just after synterp (this is what [rocq c] or [rocq
    top] do), but this does not have to be the case. In particular, IDEs such as
    [vsrocq] run the synterp phase on the whole document before proceeding with
    interp.

    In Camltac's case, we perform syntactic checks and compilation during synterp,
    and load the compiled files during interp.
 *)

type synterp_result = Compiler.output
(** Type of synterp result. *)

val synterp : ?directives:Build_directives.t -> t -> Snippet.t -> synterp_result
(** [synterp ?directives cmd snippet] performs the syntactic interpretation phase of [cmd]
    on [snippet]:

    - It performs syntactic checks and validations, and eagerly rejects
      ill-formed snippets;
    - The snippet is scaffolded using {!Scaffold.make} and written to a build
      file using {!Build_file.write};
    - The scaffolded file is compiled using {!Compiler.compile}.

    If [directives] is set, they are added as compilation arguments.

    The returned value is a {!synterp_result} that can be used by {!interp}.
 *)

(** {1 Interp} *)

val interp : ?proof:Declare.Proof.t -> t -> synterp_result -> unit
(** [interpret ?proof cmd synterp_result] performs the interp phase of [cmd]:

    - Depending on the command, the environment is properly set up.
    - The compiled file is loaded using {!Loader.load_file}.
    - The environment is cleaned up.

    If [proof] is specified, interpretation is done in the context of the given
    proof.
 *)
