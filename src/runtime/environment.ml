(** Environments for OCaml expressions. *)

open Names
open Genintern

(** An environment is represented by partial maps from identifiers to values. *)
type t =
  { notation_vars: Glob_term.glob_constr option Id.Map.t }

let empty = { notation_vars = Id.Map.empty }

let capture glb_sign =
  let notation_vars = Id.Map.map (fun _ -> None) glb_sign.intern_sign.notation_variable_status in
  { notation_vars }

let map f env =
  { notation_vars = Id.Map.map (Option.map f) env.notation_vars }

let map_unresolved f env =
  let f var = function
    | Some v -> Some v
    | None -> try f var with _ -> None
  in
  { notation_vars = Id.Map.mapi f env.notation_vars }

let variables { notation_vars } =
  Id.Map.domain notation_vars

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
  let { notation_vars } = get_env () in
  match Id.Map.find var notation_vars with
  | Some v -> v
  | None -> raise Not_found

