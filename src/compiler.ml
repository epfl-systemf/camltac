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
  | Preprocessors of Build_file.t * int * Diagnostic.t list
  | Compilation_failed of Build_file.t * int * Diagnostic.t list

let report_diagnostic diagnostic =
  let msg =
    match diagnostic.Diagnostic.severity with
    | Warning _ -> Feedback.msg_warning ?quickfix:None
    | Error -> CErrors.user_err ?info:None
    | Alert _ | Unknown -> Feedback.msg_info
  in
  msg ?loc:diagnostic.loc diagnostic.message

let report_error ~loc = function
  | Preprocessors (file, err, diagnostics) ->
     List.iter report_diagnostic diagnostics;
     CErrors.user_err ~loc
       Pp.(str "Compilation of preprocessors for " ++ str (Build_file.module_name file) ++
           str " failed with exit code " ++ int err ++ str ".")
  | Compilation_failed (file, err, diagnostics) ->
     List.iter report_diagnostic diagnostics;
     CErrors.user_err ~loc
       Pp.(str "Compilation of " ++ str (Build_file.path file) ++
           str " failed with exit code " ++ int err ++ str ".")

(** {2 Compilation method} *)

let compile ~args ~(directives: Build_directives.t) ~source mode (impl: Build_file.t) =
  let (let*) = Result.bind in
  let ppxs = directives.ppx in
  let* pp =
    match Preprocessing.prepare ~ppxs ~source:(Snippet.contents source) with
    | Ok pp -> Ok (Preprocessing.pp_flag pp)
    | Error (err, diagnostics) -> Error (Preprocessors (impl, err, diagnostics))
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
      ~source
      ?pp
      mode
      impl
  with
  | Ok (file, diagnostics) ->
     List.iter report_diagnostic diagnostics;
     Ok { file; packages }
  | Error (code, diagnostics) -> Error (Compilation_failed (impl, code, diagnostics))
