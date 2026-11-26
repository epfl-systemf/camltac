(** Synterp state. *)

(** {1 Module registry}

    The module registry is a simple registry that contains all of the
    declared modules. *)

module Module_registry = struct
  type t = entry list
  and entry =
    { name: string option;          (** Name of the module. *)
      artifact: Compiler.Artifact.t (** Module artifact. *)
    }

  let empty : t = []

  let register ~name artifact registry =
    { name; artifact } :: registry

  let artifacts registry =
    List.map (fun entry -> entry.artifact) registry

  let module_exists name registry =
    let name_equal = function
      | Some name' -> String.equal name name'
      | None       -> false
    in
    List.exists (fun entry -> name_equal entry.name) registry

  let module_name_map registry =
    let binding { name; artifact } =
      match name with
      | None      -> None
      | Some name -> Some (name, Compiler.Artifact.unit_name artifact)
    in
    List.filter_map binding registry |> CString.Map.of_list
end

(** {1 Synterp state} *)

type t = Module_registry.t

[%%if rocq >= (9, 4)]
open Summary.Ref
[%%endif]

let state =
  Summary.ref
    ~stage:Synterp
    ~name:"Camltac:SYNTERP-STATE"
    Module_registry.empty

let current () = !state

(* State-update only. *)
let cache_module ~name artifact =
  state := Module_registry.register ~name artifact !state

(** {2 Library object}

    Each module declaration is persisted to [.vo] files, so that they
    can be replayed on [Require]/[Import], according to the locality. *)

let module_declaration : Libobject.locality * (string option * Logical_artifact.t) -> Libobject.obj =
  let open Libobject in
  declare_object (
    object_with_locality
      ~stage:Synterp
      ~cache:(fun (name, artifact) -> cache_module ~name (Logical_artifact.to_physical artifact))
      ~subst:None
      ~discharge:Fun.id
      "Camltac:MODULE-DECLARATION")

let declare ~locality ~name artifact =
  let artifact = Logical_artifact.of_physical artifact in
  Lib.add_leaf (module_declaration (locality, (name, artifact)))

(** {2 Getters} *)

let module_exists   = Module_registry.module_exists
let artifacts       = Module_registry.artifacts
let module_name_map = Module_registry.module_name_map
