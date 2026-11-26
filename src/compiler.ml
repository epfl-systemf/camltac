(** Compilation of OCaml snippets. *)

(** {1 Compilation} *)

type compiled =
  { file     : Build_file.t;
    packages : string list
  }

type args =
  { packages     : string list;
    include_dirs : string list;
    open_modules : string list;
  }

type mode = Ocamlfind.mode =
  | Shared_library of { linkall : bool }
  | Executable of { linkall : bool; linkpkg : bool }
  | Compile_only
  | Infer_interface

(** {2 Compilation errors} *)

type error =
  | Preprocessors of Build_file.t * int
  | Compilation_failed of Build_file.t * int

let report_error ~loc = function
  | Preprocessors (file, err) ->
     CErrors.user_err ~loc
       Pp.(str "Compilation of preprocessors for " ++ str (Filesystem.Path.module_name (Build_file.path file)) ++
           str " failed with exit code " ++ int err ++ str ".")
  | Compilation_failed (file, err) ->
     CErrors.user_err ~loc
       Pp.(str "Compilation of " ++ str (Build_file.resolve file) ++
           str " failed with exit code " ++ int err ++ str ".")

(** {2 Compilation method} *)

let compile ~args ~(directives: Build_directives.t) ~source mode (impl: Build_file.t) =
  let (let*) = Result.bind in
  let ppxs = directives.ppx in
  let* pp =
    match Preprocessing.select_driver ~workspace:(Build_file.workspace impl) ~file:(Snippet.file source) ~ppxs ~source:(Snippet.contents source) with
    | Ok driver -> Ok (Preprocessing.pp_flag driver)
    | Error err -> Error (Preprocessors (impl, err))
  in
  let ppx_runtime_deps = List.concat_map Ocaml_packages.ppx_runtime_deps ppxs in
  let packages = ppx_runtime_deps @ directives.libraries in
  let result, diagnostics =
    Ocamlfind.ocamlc
      ~packages:(packages @ args.packages)
      ~include_dirs:(Filename.dirname (Build_file.resolve impl) :: args.include_dirs)
      ~open_modules:(args.open_modules)
      ~optimize:(`O3)
      ~extra_args:("-no-alias-deps" :: "-short-paths" :: directives.compiler_options)
      ?pp
      mode
      impl
  in
  Error_reporter.report_all ~source diagnostics;
  match result with
  | Ok file    -> Ok { file; packages }
  | Error code -> Error (Compilation_failed (impl, code))
