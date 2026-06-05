(** Runtime support for obtaining the output of dynamically linked code. *)

let tactic: unit Proofview.tactic option ref = ref None

let set_tactic t =
  tactic := Some t

let get_tactic () =
  match !tactic with
  | Some result ->
     tactic := None;
     result
  | None -> assert false
