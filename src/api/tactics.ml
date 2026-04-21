(** Standard tactic syntax. *)

(** {1 Tactic monad} *)

type 'a tactic = 'a Proofview.tactic

let return = Proofview.Monad.return
let (let*) = Proofview.Monad.(>>=)
let fail = Proofview.tclZERO

exception More_than_one_goal
(** Exception thrown when there is more than one goal in focus. *)

let with_env f =
  let* goals = Proofview.Goal.goals in
  match goals with
  | [] ->
     let* env = Proofview.tclENV in
     let* sigma = Proofview.tclEVARMAP in
     return (f env sigma)
  | [goal] ->
     let* goal in
     let env = Proofview.Goal.env goal in
     let sigma = Proofview.Goal.sigma goal in
     return (f env sigma)
  | _ :: _ ->
     fail More_than_one_goal
