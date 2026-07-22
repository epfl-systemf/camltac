(** Handles backtrack state for modules. *)

type camltac_module =
  { name: string;
    locality: Libobject.locality;
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

let camltac_module : camltac_module -> Libobject.obj =
  let open Libobject in
  let load_function _ m =
    (* Called at [Require] time. *)
    match m.locality with
    | SuperGlobal -> load_module m
    | _ -> ()
  in
  let open_function filter n m =
    (* Called at [Import] time. *)
    match m.locality with
    | Export when n = 1 -> load_module m
    | _ -> ()
  in
  declare_object
    {(default_object "camltac_module") with
      object_stage = Summary.Stage.Interp;
      cache_function = load_module; (* Always immediately load the module locally. *)
      load_function;
      open_function;
      subst_function = (fun (_, o) -> o);
      classify_function = (fun { locality } ->
        match locality with
        | Local -> Dispose
        | Export | SuperGlobal -> Substitute) }

let declare_module ~locality name compilation_output =
  let m = { name; locality; compilation_output } in
  Lib.add_leaf (camltac_module m)
