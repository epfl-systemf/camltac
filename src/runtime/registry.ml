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
