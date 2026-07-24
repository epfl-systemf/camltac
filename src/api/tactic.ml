(** Standard tactic syntax. *)

(** {1 Tactic monad} *)

type +'a tactic = 'a Proofview.tactic

let return = Proofview.Monad.return
let (let*) = Proofview.Monad.(>>=)

let fail ?(level = 0) msg = Tacticals.tclFAILn level msg
let user_error ?loc msg = Tacticals.tclZEROMSG ?loc msg

(** {1 Goal selectors} *)

[%%if rocq >= (9, 1)]
type goal_selector = Proofview.goal_range_selector

let nth n = Proofview.NthSelector n
let range i j = Proofview.RangeSelector (i, j)
let id id =
  let qualid = Libnames.qualid_of_string id in
  Proofview.IdSelector qualid

let only selectors t = Proofview.tclFOCUSSELECTORLIST selectors t
[%%else]
type goal_selector = Goal_select.t

let nth n = Goal_select.SelectNth n
let range i j =
  Goal_select.SelectList [(i, j)]
let id id =
  Goal_select.SelectId (Names.Id.of_string id)

let only selectors t =
  (* Fuse [nth] and [range] selectors. *)
  let fold acc x =
    let open Goal_select in
    match acc, x with
    | SelectList [], _ -> x
    | _, SelectAll -> Goal_select.SelectAll
    | SelectList l, SelectList l' -> Goal_select.SelectList (l @ l')
    | SelectList l, SelectNth n -> Goal_select.SelectList (l @ [(n, n)])
    | SelectNth n, SelectList l -> Goal_select.SelectList ([(n, n)] @ l)
    | _, _ -> assert false
  in
  let selectors = List.fold_left fold (SelectList []) selectors in
  Goal_select.tclSELECT selectors t
[%%endif]

let all = Proofview.tclINDEPENDENT

(** {1 Tacticals} *)
let (>>) = Proofview.Monad.(>>)

let repeat ?n t =
  match n with
  | Some n -> Tacticals.tclDO n t
  | None -> Tacticals.tclREPEAT t

let try_ = Tacticals.tclTRY
let tryif t ~then_ ~else_ = Tacticals.tclIFCATCH t (fun () -> then_) (fun () -> else_)

let (<+>) = Tacticals.tclOR
let (<||>) = Tacticals.tclORELSE

let progress t = Proofview.tclPROGRESS t
let solve t = Tacticals.tclSOLVE t

let once = Tacticals.tclONCE
let exactly_once = Tacticals.tclEXACTLY_ONCE

let first tacs = Tacticals.tclFIRST tacs
let dispatch tac1 tacs = tac1 >> Proofview.tclDISPATCHL tacs

let time ?name t = Tacticals.tclTIME name t
let timeout = Tacticals.tclTIMEOUT

let abstract ?opaque ?name t = Abstract.tclABSTRACT ?opaque name t

let ignore t = Proofview.tclIGNORE t

(** {1 Utilities} *)

let env =
  let* goals = Proofview.Goal.goals in
  match goals with
  | [goal] -> let* goal in return (Proofview.Goal.env goal)
  | _ -> Proofview.tclENV

let sigma =
  let* goals = Proofview.Goal.goals in
  match goals with
  | [goal] -> let* goal in return (Proofview.Goal.sigma goal)
  | _ -> Proofview.tclEVARMAP

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
