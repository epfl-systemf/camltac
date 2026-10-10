(** Global state manager. *)

type camltac_module =
  { name: string option;
    compilation_output: Compiler.compiled }

[%%if rocq >= (9, 4)]
open Summary.Ref
[%%endif]

(** List of names of loaded modules. *)
let loaded_modules =
  Summary.ref
    ~stage:Interp
    ~name:"camltac:loaded-modules"
    ([] : string list)

let is_loaded m =
  List.exists (String.equal m) !loaded_modules

let load_module m =
  let { name; compilation_output } = m in
  let load_module () =
    let Compiler.{ file; packages } = m.compilation_output in
    Loader.load_file ~dependencies:packages `Public file;
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
