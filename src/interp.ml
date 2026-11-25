(** Interp state.

    This module concerns itself with tracking which modules are loaded,
    and delegates the complex module loading logic to {!Module_loader}. *)

(** {1 Interp state} *)

type t = CString.Set.t (** Set of loaded modules. *)

[%%if rocq >= (9, 4)]
open Summary.Ref
[%%endif]

let state =
  Summary.ref
    ~stage:Interp
    ~name:"Camltac:INTERP-STATE"
    CString.Set.empty

let current () = !state

let add_loaded_module ~name =
  match name with
  | Some name -> state := CString.Set.add name !state
  | None      -> ()

(** {1 Module loading} *)

let is_loaded = CString.Set.mem

(** {2 Replaying modules}

    To be able to replay non-local modules from [.vo] files, we serialize the
    environment from the original module's load, so that globalization is
    performed correctly. *)

let replay_object : Libobject.locality * (Runtime.Environment.t * string option * Logical_artifact.t) -> Libobject.obj =
  let open Libobject in
  declare_object
    { (object_with_locality
         ~stage:Summary.Stage.Interp
         ~cache:(fun (env, name, out) ->
           ignore (Module_loader.load_module ~env ~name (Logical_artifact.to_physical out));
           add_loaded_module ~name)
         ~subst:None
         ~discharge:Fun.id
         "Camltac:REPLAY-MODULE")
       with cache_function = (fun _ -> ())
       (* No cache, the replay object only triggers on Require/Import *)
    }

let load_module ~locality ~name artifact =
  (* Load the module immediately to get the [env] for replay. *)
  let env = Module_loader.load_module ~name artifact in
  add_loaded_module ~name;
  match locality with
  | Libobject.Local -> ()
  | _ ->
     let artifact = Logical_artifact.of_physical artifact in
     Lib.add_leaf (replay_object (locality, (env, name, artifact)))
