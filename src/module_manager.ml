(** Handles backtrack state for modules. *)

type camltac_module =
  { name: string;
    local: bool;
    compilation_output: Compiler.output }

let loaded_modules = Summary.ref ~stage:Synterp ~name:"loaded_modules" []

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
      classify_function = (fun { local } -> if local then Libobject.Dispose else Libobject.Substitute) }

let declare_module ?(local = false) name compilation_output =
  let m = { name; local; compilation_output } in
  Lib.add_leaf (camltac_module m)
