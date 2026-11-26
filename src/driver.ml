(** Main driver. *)

open Names
open Scaffold

(** {1 Commands} *)

module Command = struct
  type t =
    | Module of module_info
    | Eval
    | Check_expression
    | Check_module

  and module_info =
    { name: string option;
      locality: Libobject.locality;
    }

  let compilation_mode = function
    | Module _ | Eval                 -> Compiler.Shared_library { linkall = true }
    | Check_expression | Check_module -> Compiler.Infer_interface
end

open Command

(** {2 Synterp} *)

type synterp_result = Command.t * Compiler.Artifact.t

(** {3 Compilation arguments} *)

let default_args =
  let open Compilation_args in
  empty
  |> add_packages ["rocq-camltac.plugin.runtime"; "rocq-camltac.plugin.api"; "ppx_rocq.runtime"]
  |> add_open_modules ["Api"; "Prelude"]

let current_args ~state =
  let modules = Synterp.artifacts state in
  let open Compilation_args in
  default_args
  |> add_packages (List.concat_map Compiler.Artifact.dependencies modules)
  |> add_include_dirs (List.map Compiler.Artifact.dirname modules)

let pp_flag ~workspace ~file ~ppxs snippet =
  match Preprocessing.select_driver ~workspace ~file ~ppxs ~source:(Snippet.contents snippet) with
  | Ok driver -> Preprocessing.pp_flag driver
  | Error err ->
     CErrors.user_err ~loc:(Snippet.loc snippet)
       Pp.(str "Compilation of PPX driver failed with exit code " ++ int err)

let compilation_args ~workspace ~file ~directives ~state snippet =
  current_args ~state
  |> Directives.extend_args directives
  |> Compilation_args.add_pp (pp_flag ~workspace ~file ~ppxs:directives.Directives.ppx snippet)

module Commands (P: Pipeline.PARAMS) = struct
  open Pipeline.Make(P)

  let compile_module ~locality ~name snippet =
    scaffold (Scaffold.Module { name }) snippet
    |> create_source_file
    |> create_merlin_file
    |> create_build_file
    |> compile (Compiler.Shared_library { linkall = true }) ~source:snippet
    |> declare_module ~locality ~name

  let eval snippet =
    let typ = infer_tactic_type snippet in
    scaffold (Scaffold.Value_tactic { typ }) snippet
    |> create_source_file
    |> create_merlin_file
    |> create_build_file
    |> compile (Compiler.Shared_library { linkall = true }) ~source:snippet

  let check_expression snippet =
    scaffold Scaffold.Expression snippet
    |> create_source_file
    |> create_merlin_file
    |> create_build_file
    |> infer_interface ~source:snippet

  let check_module snippet =
    scaffold (Scaffold.Module { name = None }) snippet
    |> generate_file ~dir:".check" ~name:P.file
    |> infer_interface ~source:snippet

  let run ~directives cmd snippet =
    match cmd with
    | Module { name; locality } -> compile_module ~locality ~name snippet
    | Eval                      -> eval snippet
    | Check_expression          -> check_expression snippet
    | Check_module              -> check_module snippet
end

let current_params ?(directives = Directives.empty) snippet =
  (module struct
      let state        = Synterp.current ()
      let workspace    = Workspace.at (Current_library.cwd ())
      let file         = Current_library.top_module_name ()
      let aliases      = CString.Map.bindings (Synterp.module_name_map state)
      let args         = compilation_args ~workspace ~file ~directives ~state snippet
      let loaded_units = Loader.loaded_units ()
  end : Pipeline.PARAMS)

let synterp ?(directives = Directives.empty) cmd snippet =
  let module P = (val current_params ~directives snippet) in
  let module S = Commands(P) in
  cmd, S.run ~directives cmd snippet

(** {2 Interpretation} *)

module Interp = struct
  open Pipeline

  let eval ?proof out =
    load_tactic out
    |> run_tactic ?proof
    |> Feedback.msg_info

  let check out =
    parse_interface out
    |> print_interface

  let run ?proof (cmd, out) =
    match cmd with
    | Module { name; locality }       -> load_module ~locality ~name out
    | Eval                            -> eval ?proof out
    | Check_expression | Check_module -> check out
end

let interp = Interp.run

(** {1 Embedded tactics} *)

module Tactic = struct

  type raw =
    { source: Snippet.t;
      artifact: Compiler.Artifact.t
    }

  type glob =
    { source: Snippet.t;
      env: Runtime.Environment.t;
      artifact: Logical_artifact.t
    }

  (** {2 Embedding} *)

  let embed (source: Snippet.t) =
    let module P = (val current_params source) in
    let open Pipeline.Make(P) in
    let artifact =
      scaffold Scaffold.Unit_tactic source
      |> create_source_file
      |> create_merlin_file
      |> create_build_file
      |> compile (Compiler.Shared_library { linkall = true }) ~source
    in
    { source; artifact }

  (** {2 Globalization} *)

  let globalize glob_sign ({ source; artifact }: raw) =
    let env = Runtime.Environment.capture glob_sign in
    let artifact = Logical_artifact.of_physical artifact in
    { source; env; artifact }

  (** {2 Module substitution} *)

  let mod_subst s glob =
    let f = Detyping.subst_glob_constr (Global.env ()) s in
    let env = Runtime.Environment.map f glob.env in
    { glob with env }

  let subst_notation_vars f glob =
    let env = Runtime.Environment.map_unresolved f glob.env in
    { glob with env }

  (** {2 Interpretation} *)

  let interp { source; env; artifact } =
    let artifact = Logical_artifact.to_physical artifact in
    Runtime.Environment.set_env env;
    Fun.protect
      (fun () -> Pipeline.load_tactic artifact)
      ~finally:Runtime.Environment.unset_env

  (** {2 Printers} *)

  let print_raw _env _evd ({ source; _ }: raw) =
    Pp.str (Snippet.contents source)

  let print_glob _env _evd ({ source; _ }: glob) =
    Pp.str (Snippet.contents source)
end
