(** Loaded modules. *)

(** {1 Loaded modules} *)

(** {2 Interp state} *)

type state =
  { modules : CString.Set.t; (** Modules currently loaded. *)
  }

[%%if rocq >= (9, 4)]
open Summary.Ref
[%%endif]

let state =
  Summary.ref
    ~name:"Camltac:loaded_modules"
    ~stage:Interp
    { modules = CString.Set.empty }

(** {2 Loading modules} *)

let is_loaded name = CString.Set.mem name !state.modules

let load_named_module ~name (out: Compiler.compiled) =
  Loader.load_file ~dependencies:out.packages `Public out.file;
  state := { modules = CString.Set.add name !state.modules }

let load_anonymous_module (out: Compiler.compiled) =
  Loader.load_file ~dependencies:out.packages `Private out.file

let load_module ~name (out: Compiler.compiled) =
  match name with
  | Some name -> load_named_module ~name out
  | None      -> load_anonymous_module out

let with_env ~env f =
  Runtime.Environment.set_env env;
  Fun.protect
    ~finally:Runtime.Environment.unset_env
    (fun () -> f (); Runtime.Environment.get_env ())

let load_module_with_env ~env ~name out =
  with_env ~env (fun () -> load_module ~name out)

(** {2 Replaying modules}

    We record non-local modules in {!Libobject} to be able to replay them from
    the [.vo] file, i.e., on [Require] or [Import].  Note that replaying modules
    take the environment from the original module's load, so that globalization
    is performed correctly. *)

let run_module_initializers ~name =
  Runtime.Output.get_module name ()

let replay_module ~env ~name (out: Compiler.compiled) =
  (* Re-trigger module initializers for already loaded modules. *)
  match name with
  | Some name when Loader.is_loaded out.file ->
     with_env ~env (fun () -> run_module_initializers ~name)
  | _ ->
     load_module_with_env ~env ~name out

open Libobject

let module_replay_object =
  declare_object
    { (object_with_locality
         ~stage:Summary.Stage.Interp
         ~cache:(fun (env, name, out) -> ignore (replay_module ~env ~name out))
         ~subst:None
         ~discharge:Fun.id
         "camltac:replay_module")
       with cache_function = (fun _ -> ())
       (* No cache, the replay object only triggers on Require/Import *)
    }

(** {2 Module registration} *)

let load_module ~locality ~name out =
  let env = load_module_with_env ~env:Runtime.Environment.empty ~name out in
  (* Record replay object for Require/Import. *)
  match locality with
  | Local -> ()
  | _ -> Lib.add_leaf (module_replay_object (locality, (env, name, out)))
