(** Module loader. *)

(** {1 Loading modules} *)

let link_named_module ~name ~dependencies ~file =
  Loader.load_file ~dependencies `Public file

let link_anonymous_module ~dependencies ~file =
  Loader.load_file ~dependencies `Private file

let link_module ~name artifact =
  let dependencies = Compiler.Artifact.dependencies artifact in
  let file = Compiler.Artifact.file artifact in
  match name with
  | Some name -> link_named_module ~name ~dependencies ~file
  | None      -> link_anonymous_module ~dependencies ~file

(** {2 Module initializers}

    If the named module is already linked in the current process, we rerun its
    module initializers instead, which were registered through
    {!Runtime.Output.register_module}.
 *)

let is_linked artifact =
  Loader.is_loaded (Compiler.Artifact.file artifact)

let run_module_initializers ~name =
  Runtime.Output.get_module name ()

let load_module ?(env = Runtime.Environment.empty) ~name artifact =
  Runtime.Environment.with_env ~env
    (fun () ->
      match name with
      | Some name when is_linked artifact -> run_module_initializers ~name
      | _                                 -> link_module ~name artifact)
