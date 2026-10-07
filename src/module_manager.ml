(** Global state manager. *)

type camltac_module =
  { name: string option;
    compilation_output: Compiler.output }

(** State required for compiling modules properly. *)
type synterp_state =
  { compiled_modules: Compiler.output CString.Map.t;
    dependencies: CString.Set.t;
    modules_dirs : CString.Set.t;
    packing_module: Build_files.t option;
  }

[%%if rocq >= (9, 4)]
open Summary.Ref
[%%endif]

let synterp_state =
  Summary.ref
    ~stage:Synterp
    ~name:"camltac:synterp-state"
    { compiled_modules = CString.Map.empty;
      dependencies = CString.Set.empty;
      modules_dirs = CString.Set.empty;
      packing_module = None
    }

(** List of names of loaded modules. *)
let loaded_modules =
  Summary.ref
    ~stage:Interp
    ~name:"camltac:loaded-modules"
    ([] : string list)

let is_loaded m =
  List.exists (String.equal m) !loaded_modules

let dependencies () =
  CString.Set.elements !synterp_state.dependencies

let modules_dirs () =
  CString.Set.elements !synterp_state.modules_dirs

(** [module_aliases ()] returns the contents of the packing module. *)
let module_aliases () =
  let module_alias (name, compilation_output) =
    let real_name = Build_files.module_name compilation_output.Compiler.compiled_file in
    Format.sprintf "module %s = %s" name real_name
  in
  (* First element = most recent, so reverse the order. *)
  let aliases = List.rev_map module_alias (CString.Map.bindings !synterp_state.compiled_modules) in
  String.concat "\n" aliases

let packing_module () =
  Option.map Build_files.module_name !synterp_state.packing_module

let generate_packing_module () =
  let impl = Build_files.(write Module (module_aliases ())) in
  let compilation_output =
    Ocamlfind.compile
      ~compile_only:true
      ~include_dirs:(modules_dirs ())
      ~extra_args:["-no-alias-deps"]
      impl
  in
  match compilation_output with
  | Ok packing_module ->
     synterp_state := { !synterp_state with packing_module = Some packing_module }
  | Error err ->
     CErrors.user_err (Pp.(str "Compilation of packing module failed with error " ++ int err ++ str "."))

let declare_module name (Compiler.{ compiled_file; dependencies } as out)  =
  let new_state =
    { !synterp_state with
      dependencies = CString.Set.add_seq (List.to_seq dependencies) !synterp_state.dependencies;
      modules_dirs = CString.Set.add (Build_files.modules_dir ~file:compiled_file ()) !synterp_state.modules_dirs;
    }
  in
  match name with
  | Some name ->
     let compiled_modules = CString.Map.add name out !synterp_state.compiled_modules in
     synterp_state := { new_state with compiled_modules };
     generate_packing_module ()
  | None ->
     (* Anonymous modules don't trigger a compilation of a new packing module. *)
     synterp_state := new_state

let load_module m =
  let { name; compilation_output } = m in
  let load_module () =
    let Compiler.{ compiled_file; dependencies } = m.compilation_output in
    Loader.load_file ~public:true ~dependencies compiled_file;
    (* Declare the module for it to be included in the module name map. *)
    declare_module name m.compilation_output
  in
  match name with
  | Some name ->
     (* Don't load the module twice. *)
     if not (is_loaded name) then begin
       load_module ();
       loaded_modules := name :: !loaded_modules;
     end
  | None -> load_module ()

(* We persist the runtime environment of each module, so that it can be
   retrieved upon [Require] or [Import]. *)
let envs = Summary.ref ~name:"camltac_envs" CString.Map.empty

let cache_envs v =
  envs := v

let merge_envs v =
  envs := CString.Map.union (fun _key _v1 v2 -> Some v2) !envs v

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
  match m.name with
  | Some name -> Lib.add_leaf (declare_envs (CString.Map.add name env !envs))
  | None -> ()

let get_env m =
  match m.name with
  | None ->
     (* Don't track anonymous modules. *)
     Runtime.Environment.empty
  | Some name ->
     try CString.Map.find name !envs
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
    open_function = (fun filter n (locality, m) -> match locality with
        | Local -> assert false
        | Export when Libobject.in_filter ~cat:None filter && n = 1 -> load_module m
        | _ -> ());
    classify_function = (fun (locality, _) -> match locality with
        | Local -> Dispose
        | Export | SuperGlobal -> Keep);
    discharge_function =
      (fun (locality,v) -> match locality with
         | Local -> None
         | Export | SuperGlobal -> Some (locality, v));
  }

let load_module ~locality name compilation_output =
  let m = { name; compilation_output } in
  Lib.add_leaf (camltac_module (locality, m))
