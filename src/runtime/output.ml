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

let modules = ref CString.Map.empty

let register_module m (f: unit -> unit) =
  modules := CString.Map.add m f !modules

let get_module m =
  match CString.Map.find_opt m !modules with
  | Some f -> f
  | None -> Fun.id
