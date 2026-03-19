(** Output registry for dynamically loaded code. *)

let registered_terms = ref []

let register_term t =
  registered_terms := t :: !registered_terms

let get_last_term () =
  match !registered_terms with
  | t :: ts ->
     registered_terms := ts;
     t
  | [] -> raise Not_found

module StringMap = Map.Make(String)

let registry = ref StringMap.empty

let register name v =
  registry := StringMap.add name (Obj.repr v) !registry

let find name =
  Obj.obj (StringMap.find name !registry)
