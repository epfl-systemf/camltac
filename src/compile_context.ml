(** Contextual arguments to the compiler. *)

(** {1 Compilation state} *)

type state =
  { modules      : Build_file.t CString.Map.t;
    packages     : CString.Set.t;
    modules_dirs : CString.Set.t;
  }

let empty_state =
  { modules      = CString.Map.empty;
    packages     = CString.Set.empty;
    modules_dirs = CString.Set.empty;
  }

(** {2 Summary state}

    This state follows backtracking. *)

[%%if rocq >= (9, 4)]
open Summary.Ref
[%%endif]

let state =
  Summary.ref
    ~stage:Synterp
    ~name:"Camltac:compilation_state"
    empty_state

let add_module (name, artifact) =
  let file = Compiler.Artifact.file artifact in
  let packages = Compiler.Artifact.dependencies artifact in
  let old_state = !state in
  state :=
    { modules      = (match name with
                     | Some name -> CString.Map.add name file old_state.modules
                     | None -> old_state.modules);
      packages     = CString.Set.add_seq (List.to_seq packages) old_state.packages;
      modules_dirs = CString.Set.add (Filename.dirname (Build_file.resolve file)) old_state.modules_dirs;
    }

(** {2 Libobject}

    Module declaration is recorded in [Libobject], so that it can be replayed
    upon [Require]/[Import]. *)

let module_object : Libobject.locality * (string option * Logical_artifact.t) -> Libobject.obj =
  let open Libobject in
  declare_object
    (object_with_locality
      "camltac-declared-module"
      ~stage:Synterp
      ~cache:(fun (name, out) -> add_module (name, Logical_artifact.to_physical out))
      ~subst:None
      ~discharge:(fun x -> x))

(** Check that a module doesn't already have this name. *)
let check_module_name = function
  | Some (name, loc) when CString.Map.mem name !state.modules  ->
     CErrors.user_err ~loc (Pp.(str "Module " ++ str name ++ str " is already defined."))
  | Some (name, _) -> Some name
  | None -> None

let declare_module ~locality ~name out =
  let name = check_module_name name in
  Lib.add_leaf (module_object (locality, (name, Logical_artifact.of_physical out)))

(** {2 Module aliases} *)

let module_alias (name, file) =
  (name, Filesystem.Path.module_name (Build_file.path file))

let module_aliases () =
  CString.Map.bindings !state.modules
  |> List.map module_alias

(** {1 Compilation context} *)

type t = Compilation_args.t

let default =
  let open Compilation_args in
  empty
  |> add_packages ["rocq-camltac.plugin.runtime"; "rocq-camltac.plugin.api"; "ppx_rocq.runtime"]
  |> add_open_modules ["Api"; "Prelude"]

let of_state (state: state) =
  let open Compilation_args in
  default
  |> add_packages (CString.Set.elements state.packages)
  |> add_include_dirs (CString.Set.elements state.modules_dirs)

let current () = of_state !state
