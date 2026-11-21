(** Scaffolding snippets. *)

(** {1 Scaffolding}

    While a snippet is valid OCaml on its own, it usually does not
    represent a complete program, since it lacks the proper setup code
    to run on its own. For example, a snippet inside a term must be a
    [unit tactic] that registers itself in {!Runtime.Output}, while the
    input to [Camltac Module] must be a whole module. These two snippets
    require different setup code to work properly.

    Scaffolding is the operation that wraps a {!Snippet.t} in additional
    setup code to turn it into a complete program. Scaffolding may also
    add structural or type constraints to capture the intended meaning
    of the snippet, so that mistakes become ordinary compilation errors
    in the user's code.

    The exact scaffolding depends on the scaffolding type {!kind}, which
    describes how the snippet is to be interpreted.
 *)

(** Describes how a snippet should be scaffolded. *)
type kind =
  | Expression
  (** A single expression. *)

  | Module of { name: string option }
  (** A whole OCaml module. *)

  | Unit_tactic
  (** A tactic of type [unit tactic]. *)

  | Value_tactic of { typ: string }
  (** A tactic of type [typ tactic]. Its return value is printed. *)

val make : kind -> Snippet.t -> string
(** [make kind snippet] scaffolds [snippet] according to [kind]. *)
