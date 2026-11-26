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

(** {1 Embedded tactics}

    OCaml tactics can be embedded in terms, Ltac, or Ltac2 expressions,
    where they are executed differently from commands. The general process
    goes through 3 distinct phases:

    - {e Embedding}: the act of inserting an OCaml snippet inside a host
      term or Ltac/Ltac2 expression;

    - {e Globalization}: the transformation from a raw, embedded snippet
      into a globalized intermediate representation that is
      location-independent and is persisted to disk.

    - {e Interpretation}: the act of producing a term or Ltac/Ltac2
      expression from a globalized snippet.

    Implementation note: the technical term for embedded values is
    "generic argument".
 *)

module Tactic : sig

  type raw
  (** "Raw" type of embedded OCaml tactics in an AST. *)

  type glob
  (** "Globalized" type of embedded OCaml tactics.
      This type is marshallable and can be persisted to [.vo] files. *)

  val embed : Snippet.t -> raw
  (** [embed snippet] embeds an OCaml tactic snippet into a host AST.
      This is the moral equivalent of {!synterp} for tactics. *)

  (** {2 Globalization} *)

  val globalize : Genintern.glob_sign -> raw -> glob
  (** [globalize glob_sign raw] globalizes the embedded OCaml tactic. *)

  (** {2 Substitutions} *)

  val mod_subst : Mod_subst.substitution -> glob -> glob
  (** [mod_subst s glob] performs the module substitution [s] in [glob]. *)

  val subst_notation_vars : (Names.variable -> Glob_term.glob_constr option) -> glob -> glob
  (** [subst_notation_vars f glob] map notations variables to their value in [glob]. *)

  (** {2 Interpretation} *)

  val interp : glob -> unit Proofview.tactic
  (** [interp glob] loads the OCaml snippet, and returns the obtained
      tactic value. *)

  (** {2 Printers} *)

  val print_raw : Environ.env -> Evd.evar_map -> raw -> Pp.t
  (** [print_raw env evd raw] prints the raw embedded OCaml tactic
      snippet. *)

  val print_glob : Environ.env -> Evd.evar_map -> glob -> Pp.t
  (** [print_glob env evd glob] prints the globalized OCaml tactic
      snippet. *)
end
