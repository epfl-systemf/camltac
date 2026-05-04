(** Output registry for dynamically loaded code. *)

let outputs : Obj.t list ref = ref []

let register_output t =
  outputs := Obj.repr t :: !outputs

let get_last_output () =
  match !outputs with
  | t :: ts ->
     outputs := ts;
     Obj.obj t
  | [] -> raise Not_found

module StringMap = Map.Make(String)

let registry = ref StringMap.empty

let register name v =
  registry := StringMap.add name (Obj.repr v) !registry

let find name =
  Obj.obj (StringMap.find name !registry)
