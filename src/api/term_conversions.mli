open Tactics

(** {1 Conversion methods} *)

module Expr : sig
  type t = Constrexpr.constr_expr
  (** Type of surface-level, concrete syntax terms returned by the parser. *)

  val of_glob_constr : Glob_term.glob_constr -> t tactic
  (** [of_glob_constr c] converts a globalized term [c] to its concrete
      syntax representation. *)

  val of_constr : EConstr.constr -> t tactic
  (** [of_constr c] converts a well-typed term [c] to its concrete syntax
      representation. *)
end

module Glob_constr : sig
  type t = Glob_term.glob_constr
  (** Type of untyped globalized terms. Globalized terms use fully qualified
      names, have resolved notations, and do not use implicit arguments. *)

  val of_expr : Expr.t -> t tactic
  (** [of_expr e] translates a concrete syntax term [e] to a globalized term by
      resolving names, notations, and by inserting implicit arguments. *)

  val of_constr : EConstr.constr -> t tactic
  (** [of_constr c] converts a well-typed term [c] to a globalized term by
      erasing its type information. *)
end

module Constr : sig
  type t = EConstr.constr

  val of_expr : Expr.t -> t tactic
  (** [of_expr e] globalizes the concrete syntax term [e] and perform
      type inference as well as type-checking on the globalized term.

      [of_expr e] is equivalent to [of_glob_constr (Glob_constr.of_expr e)]. *)

  val of_glob_constr : Glob_constr.t -> t tactic
  (** [of_glob_constr c] perform type inference and type-checks the globalized term [c]. *)
end

module Open_constr : sig
  type t = EConstr.t

  val of_expr : Expr.t -> t tactic
  (** [of_expr e] behaves like [Constr.of_expr e], except that unresolved evars are allowed
      in the resulting term. *)

  val of_glob_constr : Glob_constr.t -> t tactic
  (** [of_glob_constr c] behaves like [Constr.of_glob_constr c], except that
      unresolved evars are allowed in the resulting term. *)
end
