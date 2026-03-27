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

let register_ltac name tac =
  let open Ltac_plugin in
  let open Tacexpr in
  let mltac _ _ = tac in
  let full_name = { mltac_plugin = "mltac.plugin.runtime"; mltac_tactic = name; } in
  let () = Tacenv.register_ml_tactic full_name [|mltac|] in
  let tac = CAst.make (TacML ({ mltac_name = full_name; mltac_index = 0 }, [])) in
  let obj () =
    Tacenv.register_ltac true false (Names.Id.of_string name) tac in
  Mltop.(declare_cache_obj_full (interp_only_obj obj) "mltac.plugin.runtime")

(* TODO: Remove duplication between [spec] and [typ].
   [spec] is an abstract type that cannot be pattern-matched. *)
let register_ltac2 name spec typ f =
  let open Ltac2_plugin in
  let full_name = Tac2expr.{ mltac_plugin = "mltac.plugin.runtime"; mltac_tactic = name } in
  Tac2externals.define full_name spec f;
  (* Emulate Ltac2 @external definition *)
  let loc_name = CAst.make (Names.Id.of_string name) in
  let loc_typ = CAst.make typ in
  Tac2entries.register_primitive loc_name loc_typ full_name
