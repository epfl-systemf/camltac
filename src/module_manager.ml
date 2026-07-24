(** Handles backtrack state for modules. *)

type camltac_module =
  { name: string;
    compilation_output: Compiler.output }

type state =
  { loaded_modules: camltac_module list;
    loaded_dependencies: string list;
    packing_module: string option;
  }

let state =
  Summary.ref
    ~stage:Synterp
    ~name:"state"
    { loaded_modules = []; loaded_dependencies = []; packing_module = None }

let is_loaded m =
  let module_name_eq m' = String.equal m'.name m in
  List.exists module_name_eq !state.loaded_modules

let loaded_dependencies () =
  !state.loaded_dependencies

let module_name filename =
  Filename.basename filename
  |> Filename.remove_extension
  |> String.capitalize_ascii

(** [module_aliases ()] returns the contents of the packing module. *)
let module_aliases () =
  let module_alias { name; compilation_output } =
    let real_name = module_name compilation_output.compiled_file in
    Format.sprintf "module %s = %s" name real_name
  in
  (* First element = most recent, so reverse the order. *)
  let aliases = List.rev_map module_alias !state.loaded_modules in
  String.concat "\n" aliases

let packing_module () =
  Option.map module_name !state.packing_module

let generate_packing_module () =
  let impl = Build_files.save_module (module_aliases ()) in
  let compilation_output =
    Ocamlfind.compile
      ~compile_only:true
      ~include_dirs:[Build_files.modules_dir]
      ~extra_args:["-no-alias-deps"]
      impl
  in
  match compilation_output with
  | Ok packing_module ->
     state := { !state with packing_module = Some packing_module }
  | Error err ->
     CErrors.user_err (Pp.fmt "Compilation of packing module failed with error %d." err)

let load_module m =
  let { name; compilation_output } = m in
  if not (is_loaded name) then begin
     let Compiler.{ compiled_file; dependencies } = compilation_output in
     Loader.load_file ~public:true ~dependencies compiled_file;
     state := { !state with loaded_modules = m :: !state.loaded_modules;
                            loaded_dependencies = dependencies @ !state.loaded_dependencies };
     generate_packing_module ()
  end

(* We persist the runtime environment of each module, so that it can be
   retrieved upon [Require] or [Import]. *)
let envs = Summary.ref ~name:"camltac_envs" CString.Map.empty

let cache_envs v =
  envs := v

let merge_envs v =
  envs := CString.Map.union (fun key v1 v2 -> Some v2) !envs v

let declare_envs : Runtime.Environment.t CString.Map.t -> Libobject.obj =
  let open Libobject in
  declare_object
    { (default_object "CAMLTAC-ENVS") with
      cache_function = cache_envs;
      load_function = (fun _ -> merge_envs);
      open_function = (fun _ _ -> merge_envs);
      classify_function = (fun _ -> Keep);
    }

let set_env m env =
  Lib.add_leaf (declare_envs (CString.Map.add m.name env !envs))

let get_env m =
  try CString.Map.find m.name !envs
  with Not_found ->
    let env = Runtime.Environment.empty in
    set_env m env;
    env

let camltac_module : Libobject.locality * camltac_module -> Libobject.obj =
  let open Libobject in
  let load_module m =
    (* The environment of the module is key to globalization working properly,
       since it is persisted between [cache_function] and [load_function]. *)
    let env = get_env m in
    Runtime.Environment.set_env env;
    load_module m;
    let env = Runtime.Environment.get_env () in
    set_env m env;
    Runtime.Environment.unset_env ()
  in
  declare_object
  {
    (default_object ~stage:Summary.Stage.Interp "camltac_module") with
    cache_function = (fun (_, m) -> load_module m);
    load_function = (fun _ (locality, m) -> match locality with
        | Local -> assert false
        | Export -> ()
        | SuperGlobal -> load_module m);
    open_function = simple_open (fun (locality, m) -> match locality with
        | Local -> assert false
        | Export -> load_module m
        | SuperGlobal -> ());
    classify_function = (fun (locality, _) -> match locality with
        | Local -> Dispose
        | Export | SuperGlobal -> Keep);
    discharge_function =
      (fun (locality,v) -> match locality with
         | Local -> None
         | Export | SuperGlobal -> Some (locality, v));
  }

let declare_module ~locality name compilation_output =
  let m = { name; compilation_output } in
  Lib.add_leaf (camltac_module (locality, m))
