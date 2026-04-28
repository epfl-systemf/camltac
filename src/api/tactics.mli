(** {1 Tactic monad} *)

type +'a tactic = 'a Proofview.tactic
(** The tactic monad. *)

val return : 'a -> 'a tactic
(** “Unit” operation of the tactic monad. *)

val ( let* ) : 'a tactic -> ('a -> 'b tactic) -> 'b tactic
(** “Bind” operation of the tactic monad:
    [let* x = f in y] is equivalent to [bind f (fun x -> y)].
 *)

val fail : ?level:int -> Pp.t -> 'a tactic
(** Backtracking “zero” operation of the tactic monad: [fail ?level msg] creates
    a tactic that fails with message [msg], where [level] specifies how many
    backtracks are produced. *)

val user_error : ?loc:Loc.t -> Pp.t -> 'a tactic
(** Non-backtracking “zero” operation of the tactic: [user_error ?loc msg]
    creates an error message. *)

(** {2 Utilities} *)

val with_env : (Environ.env -> Evd.evar_map -> 'a tactic) -> 'a tactic
(** [with_env t] executes [t] in the current environment and evar map, and
    returns the result as a tactic.

    The “current environment” is dependent on the context:
    - If there are no goals in focus, the current environment is the global environment.
    - If there is a single goal in focus, the current environment is the goal's environment.
    - Otherwise, if there is more than one goal in focus, the tactic fails with an error.
 *)

(** {1 Tactic syntax} *)

(** {2 Goal selection} *)

type goal_selector = Proofview.goal_range_selector

val nth : int -> goal_selector
(** [nth n] focuses on the [n]-th goal. *)

val range : int -> int -> goal_selector
(** [range i j] focuses on goals [i] to [j], inclusive. *)

val id : string -> goal_selector
(** [id name] focuses on the goal named [id]. *)

val with_focus : goal_selector list -> 'a tactic -> 'a tactic
(** [with_focus selector tac] applies tactic [tac] to goal selected by [selector]. *)

val all : unit tactic -> unit tactic
(** [all tac] applies tactic [tac] to all goals. *)

(** {2 Tacticals} *)

val ( >> ) : unit tactic -> 'a tactic -> 'a tactic
(** Sequencing operator: [t1 >> t2] executes tactic [t1] and [t2] in sequence,
    where [t2] is applied to all goals produced by [t1]. *)

val repeat : ?n:int -> unit tactic -> unit tactic
(** Repetition: [repeat ?n t] executes tactic [t] until successes have been depleted.
    If [n] is specified, [repeat n t] performs tactic [t] at most [n] times. *)

val try_ : unit tactic -> unit tactic
(** [try_ t] executes tactic [t], catching any error that [t] may produce. *)

val tryif : unit tactic -> then_:(unit tactic) -> else_:(unit tactic) -> unit tactic
(** [tryif t ~then_ ~else_] executes tactic [then_] if [t] is successful, or
    [else_] otherwise. *)

val (+) : unit tactic -> unit tactic -> unit tactic
(** Branching with backtracking: [t1 + t2] first evaluates [t1] to each focused
    goal independently, inserting a backtracking point. If [t1] fails, [t2] is
    evaluated. *)

val (||) : unit tactic -> unit tactic -> unit tactic
(** Branching without backtracking: [t1 || t2] evaluates [t1] to each focused
    goal independently. If [t1] fails immediately, [t2] is tried. *)

val first : unit tactic list -> unit tactic
(** [first tacs] independently applies to each goal the first tactic in [tacs]
    that succeeds. *)

val solve : unit tactic list -> unit tactic
(** [solve tacs] independently applies to each goal the first tactic in [tacs]
    that solves the goal. *)

val progress : 'a tactic -> 'a tactic
(** [progress t] behaves like [t], except that [progress t] fails if [t]
    did not make progress on the goal. *)

val once : unit tactic -> unit tactic
(** [once t] behaves like [t], except that it fails if [t] has more than one
    success. *)

val exactly_once : unit tactic -> unit tactic
(** [exactly_once t] behaves like [t], except that it fails if [t] does not have
    exactly one success.

    Warning: [exactly_once] is considered experimental.
    @see https://rocq-prover.org/doc/master/refman/proof-engine/ltac.html#rocq:tacn.exactly_once
 *)

val (>) : unit tactic -> 'a tactic list -> 'a list tactic
(** Dispatch tactical: [t > [t1; t2; …]] executes tactic [t], followed by
    dispatching [t1], …, [tn] to each of the resulting goals. *)

val time : ?name:string -> 'a tactic -> 'a tactic
(** [time ?name t] times the execution of tactic [t]. *)

val timeout : int -> unit tactic -> unit tactic
(** [timeout n t] executes tactic [t] for at most [n] seconds, failing if [t]
    did not complete in [n] seconds. *)

val abstract : ?opaque:bool -> ?name:Names.Id.t -> unit tactic -> unit tactic
(** [abstract ?opaque ?name t] saves the result of the execution of tactic [t]
    as an optionally named subproof. *)

(** {1 Tactics} *)

open Ltac2_plugin.Tac2api
include module type of Ltac2.Std
