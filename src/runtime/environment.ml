(** Environments for OCaml expressions. *)

open Names
open Genintern

(** An environment is represented by partial maps from identifiers to values. *)
type t = Glob_term.glob_constr option Id.Map.t

let empty = Id.Map.empty

let capture glb_sign =
  Id.Map.map (fun _ -> None) glb_sign.intern_sign.notation_variable_status

let map f env =
  Id.Map.map (Option.map f) env

let map_unresolved f env =
  let f var = function
    | Some v -> Some v
    | None -> try f var with _ -> None
  in
  Id.Map.mapi f env

let variables env =
  Id.Map.domain env

let env = ref None

exception Missing_environment

let get_env () =
  match !env with
  | Some env -> env
  | None -> raise Missing_environment

let set_env e =
  env := Some e

let unset_env () =
  env := None

let lookup var =
  let env = get_env () in
  match Id.Map.find var env with
  | Some v -> v
  | None -> raise Not_found

let persist ~id glob_constr =
  let v = Id.of_string_soft id in
  try lookup v
  with
  | Missing_environment ->
     (* Do nothing if there's no environment. *)
     glob_constr ()
  | Not_found ->
    let env = get_env () in
    let glob_constr = glob_constr () in
    let env = Id.Map.add v (Some glob_constr) env in
    set_env env;
    glob_constr
