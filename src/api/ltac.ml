(** Ltac1 FFI *)

module FFI = struct
  [%%if rocq >= (9, 2)]
  let declare_cache_object obj =
    Mltop.(declare_cache_obj_full (interp_only_obj obj) "camltac.plugin.runtime")
  [%%else]
  let declare_cache_object obj =
    Mltop.declare_cache_obj obj "camltac.plugin.runtime"
  [%%endif]

  let define name tac =
    let open Ltac_plugin in
    let open Tacexpr in
    let mltac _ _ = tac in
    let full_name = { mltac_plugin = "camltac.plugin.runtime"; mltac_tactic = name; } in
    let () = Tacenv.register_ml_tactic full_name [|mltac|] in
    let tac = CAst.make (TacML ({ mltac_name = full_name; mltac_index = 0 }, [])) in
    let obj () =
      Tacenv.register_ltac true false (Names.Id.of_string name) tac in
    declare_cache_object obj
end
