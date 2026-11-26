(** Main driver. *)

(** {1 Vernacular commands}

    Rocq evaluates commands in two distinct phases:

    - Syntactic interpretation, or {e synterp}, does enough to be able
      to parse the file.
    - Interpretation, or {e interp}, performs the effect of the command.

    Usually, interp runs just after synterp (this is what [rocq c] or
    [rocq top] do), but this does not have to be the case. In
    particular, IDEs such as [vsrocq] run the synterp phase on the whole
    document before proceeding with interp.

    In Camltac's case, we perform syntactic checks and compilation
    during synterp, and load the compiled files during interp.
 *)

module Command : sig
  (** Type of vernacular commands. *)
  type t =
    | Module of module_info
    (** OCaml top-level declarations:
        [Camltac Module M := ocaml:(…)] when [name] is [Some "M"];
        [Camltac Run ocaml:(…)] when [name] is [None]. *)

    | Eval
    (** Evaluation of OCaml tactics:
        [Camltac Eval ocaml:(…)]. *)

    | Check_expression
    (** Type-checking OCaml expressions:
        [Camltac Check ocaml:(…)]. *)

    | Check_module
    (** Type-checking OCaml modules:
        [Camltac Check M]. *)

    | Tactic_in_term
    (** Tactic-in-term modality: [Definition x := ocaml:(…)]. *)

    | Tactic_in_Ltac
    (** Tactic-in-Ltac modality: [Ltac f := ocaml:(…)]. *)

    | Tactic_in_Ltac2
    (** Tactic-in-Ltac2 modality: [Ltac2 f () := ocaml:(…)]. *)

  and module_info =
    { name: string option;
      (** Name of the module, or [None] for [Camltac Run]. *)

      locality: Libobject.locality;
      (** Locality of the module. *)
    }
end

(** {2 Synterp} *)

type synterp_result
(** The result of running synterp on a command. *)

val synterp : ?directives:Directives.t -> Command.t -> Snippet.t -> synterp_result
(** [synterp ?directives cmd snippet] performs the syntactic
    interpretation phase of [cmd] on [snippet]:

    - It performs syntactic checks and validations, and eagerly rejects
      ill-formed snippets;
    - The snippet is scaffolded using {!Scaffold.make} and written to a
      source file using {!Source_file.create}.
    - A build file is created using {!Build_file.copy_source};
    - The build file is compiled using {!Compiler.compile}.

    If [directives] is set, they are added as compilation arguments.

    Compilation errors are reported by {!Error_reporter}.

    The returned value is a {!synterp_result} that can be used by
    {!interp}.
 *)

(** {2 Interp} *)

val interp : ?proof:Declare.Proof.t -> synterp_result -> unit
(** [interpret ?proof synterp_result] performs the interp phase of
    [synterp_result]:

    - Depending on the command, the environment is properly set up.
    - The compiled file is loaded using {!Loader.load_file} or
      {!Module_loader.load_module}.
    - The environment is cleaned up. *)
