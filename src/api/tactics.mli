type +'a tactic = 'a Proofview.tactic
(** The tactic monad. *)

val return : 'a -> 'a tactic
(** “Unit” operation of the tactic monad. *)

val ( let* ) : 'a tactic -> ('a -> 'b tactic) -> 'b tactic
(** “Bind” operation of the tactic monad.
    [let* x = f in y] is equivalent to [bind f (fun x -> y)].
 *)

val fail : ?info:Exninfo.info -> exn -> 'a tactic
(** “Zero” operation of the tactic monad:
    [fail e] creates a tactic that fails with exception [e]. *)

exception More_than_one_goal
(** Exception thrown when there is more than one goal in focus. *)

val with_env : (Environ.env -> Evd.evar_map -> 'a) -> 'a tactic
(** [with_env f] executes [f] in the current environment and evar map, and
    returns the result as a tactic.

    The “current environment” is dependent on the context:
    - If there are no goals in focus, the current environment is the global environment.
    - If there is a single goal in focus, the current environment is the goal's environment.
    - Otherwise, if there is more than one goal in focus, the tactic fails with [More_than_one_goal].
 *)
