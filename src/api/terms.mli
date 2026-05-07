(** Term API. *)

open Tactics

(** {1 Term representations} *)

(** Rocq features several different representation of terms, each serving a
    different purpose:

    - {!Constrexpr.constr_expr} is the type of concrete syntax terms, obtained
      directly by parsing user input.

    - {!Glob_term.glob_constr} is an intermediate representation where names are
      fully qualified, notations have been resolved, and all arguments are
      explicited.

    - {!EConstr.constr} and {!EConstr.t} are well-typed terms that perform evar
      substitution on-the-fly using an evar map ({!Evd.evar_map}). This is the
      preferred representation of well-typed terms in tactics, as such a map is
      provided by the tactic monad.

    - {!Constr.t} is the kernel representation of terms. We should never
      manipulate it and always use {!EConstr.constr} instead.
 *)

type constrexpr = Constrexpr.constr_expr
(** Type of concrete syntax terms returned by the parser. *)

type glob_constr = Glob_term.glob_constr
(** Type of globalized untyped terms. Globalized terms use fully qualified
    names, have resolved notations, and do not use implicit arguments. *)

type constr = EConstr.constr
(** Type of well-typed terms. *)

type open_constr = EConstr.t
(** Type of well-typed terms, potentially with holes (evars). *)

(** {1 Conversion methods} *)

module Expr : sig
  type t = constrexpr
  (** Type of concrete syntax terms returned by the parser. *)

  val of_glob_constr : glob_constr -> t tactic
  (** [of_glob_constr c] converts a globalized term [c] to its concrete
      syntax representation. *)

  val of_constr : constr -> t tactic
  (** [of_constr c] converts a well-typed term [c] to its concrete syntax
      representation. *)
end

module Glob_constr : sig
  type t = glob_constr
  (** Type of globalized untyped terms. Globalized terms use fully qualified
      names, have resolved notations, and do not use implicit arguments. *)

  val of_constrexpr : constrexpr -> t tactic
  (** [of_constrexpr e] translates a concrete syntax term [e] to a globalized term by
      resolving names, notations, and by inserting implicit arguments. *)

  val of_constr : constr -> t tactic
  (** [of_constr c] converts a well-typed term [c] to a globalized term by
      erasing its type information. *)
end

module Constr : sig
  type t = constr
  (** Type of well-typed terms. *)

  val of_constrexpr : constrexpr -> t tactic
  (** [of_constrexpr e] globalizes the concrete syntax term [e] and perform
      type inference as well as type-checking on the globalized term.

      [of_constrexpr e] is equivalent to [of_glob_constr (Glob_constr.of_constrexpr e)]. *)

  val of_glob_constr : glob_constr -> t tactic
  (** [of_glob_constr c] perform type inference and type-checks the globalized term [c]. *)
end

module Open_constr : sig
  type t = open_constr
  (** Type of well-typed terms, potentially with holes (evars). *)

  val of_constrexpr : constrexpr -> t tactic
  (** [of_constrexpr e] behaves like [Constr.of_constrexpr e], except that
      unresolved evars are allowed in the resulting term. *)

  val of_glob_constr : glob_constr -> t tactic
  (** [of_glob_constr c] behaves like [Constr.of_glob_constr c], except that
      unresolved evars are allowed in the resulting term. *)
end
