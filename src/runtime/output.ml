(** Runtime support for obtaining the output of dynamically linked code. *)

let tactic: Obj.t option ref = ref None

let set_tactic t =
  tactic := Some (Obj.repr t)

let get_tactic () =
  match !tactic with
  | Some result ->
     tactic := None;
     Obj.obj result
  | None -> assert false
