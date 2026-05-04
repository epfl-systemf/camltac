(** API for parsing terms, tactics, etc. *)

open Names

(** {1 Parsing functions} *)

val parse : ?loc:Loc.t -> 'a Procq.Entry.t -> string -> 'a
(** [parse entry s] parses string [s] using the grammar rule associated to the
    [entry].

    @see [Procq.Constr] Main list of pre-defined entries.
 *)

val parse_constrexpr : ?loc:Loc.t -> string -> Constrexpr.constr_expr
(** [parse_constrexpr s] parses the AST of a Rocq term from string [s].

    [parse_constrexpr] is the most basic method for parsing terms: it does not
    resolve names or implicit arguments, nor does it not type-check the term
    obtained by the parser. To obtain terms with more guarantees, use
    [glob_constr_of_string] or [constr_of_string] instead.
  *)

val parse_ident : ?loc:Loc.t -> string -> Names.Id.t
(** [parse_ident s] parses an identifier from string [s]. *)

val parse_qualid : ?loc:Loc.t -> string -> Libnames.qualid
(** [parse_qualid s] parses a qualified identifier from string [s]. *)

val parse_pattern : ?loc:Loc.t -> string -> Constrexpr.constr_expr
(** [parse_pattern s] parse a pattern (from match expressions) from string [s]. *)

val parse_vernac : ?loc:Loc.t -> string -> Vernacexpr.vernac_control
(** [parse_vernac s] parse the vernacular command [s].

    The command [s] can include meta-vernaculars such as [Time] or [Fail]. *)

val parse_ltac : ?loc:Loc.t -> string -> Ltac_plugin.Tacexpr.raw_tactic_expr
(** [parse_ltac s] parses an Ltac1 expression from string [s]. *)

val parse_ltac2 : ?loc:Loc.t -> string -> Ltac2_plugin.Tac2expr.raw_tacexpr
(** [parse_ltac2 s] parses an Ltac2 expression from string [s]. *)

(** {1 Parsing tactics} *)

val glob_constr_of_string : ?loc:Loc.t -> string -> Glob_term.glob_constr Proofview.tactic
(** [glob_constr_of_string s] parses a Rocq term from string [s], globalizing
    names and resolving notations.

    The resulting term is not type-checked. To type-check it, use
    [Term_conversions.Constr.of_glob_constr].

    @see [constr_of_string]
 *)

val constr_of_string : ?loc:Loc.t -> string -> EConstr.constr Proofview.tactic
(** [constr_of_string s] parses an evar-free Rocq term from string [s].

    @see [open_constr_of_string]
 *)

val open_constr_of_string : ?loc:Loc.t -> string -> EConstr.t Proofview.tactic
(** [open_constr_of_string s] behaves like [constr_of_string], but evars are
    allowed in the resulting term. *)

(** {1 Parsing with antiquotations} *)

(** An antiquotation is a hole that is substituted by an expression at parsing time.
    They are denoted by {v %{x} v} or {v %kind:{x} v}, where [x] is a valid
    OCaml identifier. Methods that can handle antiquotations are called {i
    quasi-parsing methods}.

    For example, while ["1 + 1"] can be immediately parsed to a term, parsing
    ["1 + %{x}"] requires substituting the value of the OCaml variable [x]
    before continuing.

    All quasi-parsing methods below therefore take an additional argument,
    [context], that represents the substitution from names to OCaml
    expressions. The type of the context depends on the type of holes allowed,
    i.e., terms in terms, strings in vernaculars, etc.
 *)

(** Types of antiquotations. *)
type antiquotation =
  [ `Constr of EConstr.constr         (** {v %{…} v} or {v %constr:{…} v} *)
  | `Preterm of Glob_term.glob_constr (** {v %preterm:{…} v} *)
  | `Expr of Constrexpr.constr_expr   (** {v %expr:{…} v} *)
  ]

val quasiparse_constrexpr : ?loc:Loc.t -> string -> antiquotation list -> Constrexpr.constr_expr
(** [quasiparse_constrexpr s context] behaves like [parse_constexpr s], except that
    antiquotations of the form {v %{n} v} are replaced by [List.nth context n]. *)

val glob_constr_of_quasistring : ?loc: Loc.t -> string -> antiquotation list -> Glob_term.glob_constr Proofview.tactic
(** [glob_constr_of_quasistring s context] behaves like [glob_constr_of_string s],
    except that antiquotations of the form {v %{n} v} are replaced by [List.nth context n].

    @see [glob_constr_of_string]
 *)

val constr_of_quasistring : ?loc:Loc.t -> string -> antiquotation list -> EConstr.constr Proofview.tactic
(** [constr_of_quasistring s context] behaves like [constr_of_string s], except that
    antiquotations of the form {v %{0} v} are replaced by [List.nth context n].

    @see [constr_of_string]
    @see [openconstr_of_quasistring]
 *)

val open_constr_of_quasistring : ?loc:Loc.t -> string -> antiquotation list -> EConstr.t Proofview.tactic
(** [open_constr_of_quasistring s] behaves like [open_constr_of_string], except that
    antiquotations of the form {v %{n} v} are replaced by [List.nth context n].

    @see [open_constr_of_string]
 *)
