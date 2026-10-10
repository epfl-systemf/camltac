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

let ppx_runtime_deps ppxs =
  let find_value preds ppx prop =
    let value = Findlib.package_property preds ppx prop in
    String.split_on_char ' ' value
  in
  let ppx_runtime_deps ppx =
    (* Check ppx_runtime_deps first. *)
    try find_value [] ppx "ppx_runtime_deps"
    with Not_found ->
       try find_value ["custom_ppx"] ppx "requires"
       with Not_found -> []
  in
  List.concat_map ppx_runtime_deps ppxs

let compile ~args ~(directives: Build_directives.t) mode (impl: Build_file.t) =
  let (let*) = Result.bind in
  let* pp =
    match Preprocessors.create directives.ppx with
    | Ok Default -> Ok "ppx_rocq"
    | Ok (Custom driver) -> Ok (Build_file.locate driver)
    | Error err -> Error (Preprocessors (impl, err))
  in
  let ppx_runtime_deps = ppx_runtime_deps directives.ppx in
  let packages = ppx_runtime_deps @ directives.libraries in
  match
    Ocamlfind.ocamlc
      ~packages:(packages @ args.packages)
      ~include_dirs:((Build_file.layout impl).modules :: args.include_dirs)
      ~open_modules:(args.open_modules)
      ~optimize:(`O3)
      ~extra_args:("-short-paths" :: directives.compiler_options)
      ~pp
      mode
      impl
  with
  | Ok file -> Ok { file; packages  }
  | Error code -> Error (Compilation_failed (impl, code))
