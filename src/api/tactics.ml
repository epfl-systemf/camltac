(** Standard tactic syntax. *)

(** {1 Tactic monad} *)

type +'a tactic = 'a Proofview.tactic

let return = Proofview.Monad.return
let (let*) = Proofview.Monad.(>>=)
let fail ?(level = 0) msg = Tacticals.tclFAILn level msg
let user_error ?loc msg = Tacticals.tclZEROMSG ?loc msg

(** {2 Utilities} *)

let with_env t =
  let* goals = Proofview.Goal.goals in
  match goals with
  | [] ->
     let* env = Proofview.tclENV in
     let* sigma = Proofview.tclEVARMAP in
     t env sigma
  | [goal] ->
     let* goal in
     let env = Proofview.Goal.env goal in
     let sigma = Proofview.Goal.sigma goal in
     t env sigma
  | _ :: _ ->
     user_error (Pp.str "More than one goal is focussed.")

(** {1 Tactic syntax} *)

(** {2 Goal selectors} *)

type goal_selector = Proofview.goal_range_selector

let nth n = Proofview.NthSelector n
let range i j = Proofview.RangeSelector (i, j)
let id id =
  let qualid = Libnames.qualid_of_string id in
  Proofview.IdSelector qualid

let with_focus selectors t = Proofview.tclFOCUSSELECTORLIST selectors t

let all = Proofview.tclINDEPENDENT

(** {2 Tacticals} *)

let (let*) = (let*)
let (>>) = Proofview.Monad.(>>)

let repeat ?n t =
  match n with
  | Some n -> Tacticals.tclDO n t
  | None -> Tacticals.tclREPEAT t

let try_ = Tacticals.tclTRY
let tryif t ~then_ ~else_ = Tacticals.tclIFCATCH t (fun () -> then_) (fun () -> else_)

let (+) = Tacticals.tclOR
let (||) = Tacticals.tclORELSE

let progress t = Proofview.tclPROGRESS t
let solve t = Tacticals.tclSOLVE t

let once = Tacticals.tclONCE
let exactly_once = Tacticals.tclEXACTLY_ONCE

let first tacs = Tacticals.tclFIRST tacs
let (>) tac1 tacs = tac1 >> Proofview.tclDISPATCHL tacs

let time ?name t = Tacticals.tclTIME name t
let timeout = Tacticals.tclTIMEOUT

let abstract ?opaque ?name t = Abstract.tclABSTRACT ?opaque name t

(** {2 Lifting operations} *)

let of_list tacs =
  CList.fold_right (fun t acc ->
      let* v = t in
      let* acc in
      return (v :: acc)
  ) tacs (return [])

let of_array tacs =
  let* list = CArray.fold_right (fun t acc ->
    let* v = t in
    let* acc in
    return (v :: acc)
  ) tacs (return [])
  in return (Array.of_list list)

(** {1 Basic tactics} *)

open Ltac2_plugin
open Tac2api

include Ltac2.Std
