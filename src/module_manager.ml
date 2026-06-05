(** Handles backtrack state for modules. *)

type camltac_module =
  { name: string;
    compilation_output: Compiler.output }

let loaded_modules = Summary.ref ~stage:Synterp ~name:"loaded_modules" []

let get_loaded_modules () =
  !loaded_modules

let set_loaded_modules list =
  loaded_modules := list

let reset_loaded_modules () =
  set_loaded_modules []

let () = Summary.(
    declare_summary "camltac_modules"
      { stage = Summary.Stage.Synterp;
        freeze_function = get_loaded_modules;
        unfreeze_function = set_loaded_modules;
        init_function = reset_loaded_modules;
      })

let load_module { name; compilation_output } =
  if not (List.mem name !loaded_modules) then begin
     let Compiler.{ compiled_file; dependencies } = compilation_output in
     Loader.load_file ~public:true ~dependencies compiled_file;
     loaded_modules := name :: !loaded_modules
  end

let camltac_module : camltac_module -> Libobject.obj =
  let open Libobject in
  declare_object
    {(default_object "camltac_module") with
      object_stage = Summary.Stage.Synterp;
      cache_function = load_module;
      load_function = (fun _ m -> load_module m);
      subst_function = (fun (_, o) -> o);
      classify_function = (fun _ ->
        (* TODO: Implement locality. *)
        Libobject.Substitute) }

let declare_module name compilation_output =
  let m = { name; compilation_output } in
  Lib.add_leaf (camltac_module m)
  (* TODO: Check if we should do the same thing as Libobject.declare_ml_objects *)
