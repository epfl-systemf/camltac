(** Environments for OCaml expressions. *)

(** {1 Environment} *)

(** An environment is a mapping from variables to values in which OCaml snippet
    are evaluated. *)

open Names

(** Type of environments. *)
type t = Glob_term.glob_constr option Id.Map.t

(** {2 Creating an environment} *)

(** Return the empty environment. *)
val empty : t

(** Capture the environment at internalization time. *)
val capture : Genintern.glob_sign -> t

(** {2 Operations} *)

(** [map f env] applies [f] to every value of the environment. *)
val map : (Glob_term.glob_constr -> Glob_term.glob_constr) -> t -> t

(** [map_unresolved f context] applies [f] to every unresolved variable of the
    environment. [f] can return [None] to indicate failure. *)
val map_unresolved : (Id.t -> Glob_term.glob_constr option) -> t -> t

(** Return the set of variables of the environment. *)
val variables : t -> Id.Set.t

(** {2 Implicit environment} *)

(** The implicit environment is the environment that is available
    at runtime for a given snippet.  It can be controlled through the [set_env]
    and [unset_env] methods. *)

(** Exception raised when an implicit environment was expected, but none are
    available. *)
exception Missing_environment

(** Return the current implicit environment, or raises [Missing_environment] if
    there is no such environment. *)
val get_env : unit -> t

(** Set the current implicit environment that is available to the runtime. *)
val set_env : t -> unit

(** Clear the current environment. *)
val unset_env : unit -> unit

(** Find the value associated to the given variable in the current implicit
    environment.

    Raises [Missing_environment] if no environment was set using [set_env].
    Raises [Not_found] if the given variable has no value associated to it. *)
val lookup : Id.t -> Glob_term.glob_constr

(** Persists the given glob_constr in the current implicit environment,
    or returns the already persisted value. *)
val persist : id:string -> (unit -> Glob_term.glob_constr) -> Glob_term.glob_constr
