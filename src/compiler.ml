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

let pp_error = function
  | Preprocessors (file, err) ->
     Pp.(str "Compilation of preprocessors for " ++ str (Build_file.module_name file) ++
         str " failed with exit code " ++ int err ++ str ".")
  | Compilation_failed (file, err) ->
     Pp.(str "Compilation of " ++ str (Build_file.path file) ++
         str " failed with exit code " ++ int err ++ str ".")

(** {2 Compilation method} *)

let compile ~args ~(directives: Build_directives.t) mode (impl: Build_file.t) =
  let (let*) = Result.bind in
  let ppxs = directives.ppx in
  let* pp =
    match Preprocessing.prepare ~ppxs ~source:(Build_file.read impl) with
    | Ok pp -> Ok (Preprocessing.pp_flag pp)
    | Error err -> Error (Preprocessors (impl, err))
  in
  let ppx_runtime_deps = Preprocessing.runtime_deps ~ppxs in
  let packages = ppx_runtime_deps @ directives.libraries in
  match
    Ocamlfind.ocamlc
      ~packages:(packages @ args.packages)
      ~include_dirs:((Build_file.layout impl).modules :: args.include_dirs)
      ~open_modules:(args.open_modules)
      ~optimize:(`O3)
      ~extra_args:("-no-alias-deps" :: "-short-paths" :: directives.compiler_options)
      ?pp
      mode
      impl
  with
  | Ok file -> Ok { file; packages  }
  | Error code -> Error (Compilation_failed (impl, code))
