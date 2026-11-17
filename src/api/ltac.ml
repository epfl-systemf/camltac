(** Ltac1 FFI *)

module FFI = struct
  let define name tac =
    let open Ltac_plugin in
    let open Tacexpr in
    let mltac _ _ = tac in
    let full_name = { mltac_plugin = "rocq-camltac.plugin.runtime"; mltac_tactic = name; } in
    let () = Tacenv.register_ml_tactic full_name [|mltac|] in
    let tac = CAst.make (TacML ({ mltac_name = full_name; mltac_index = 0 }, [])) in
    Tacenv.register_ltac true false (Names.Id.of_string name) tac
end
