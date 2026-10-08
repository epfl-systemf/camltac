(** Compilation of OCaml snippets to shared libraries. *)

(** List of Rocq packages that are automatically linked in. *)
let rocq_packages = Ocamlfind.list_packages ~prefix:"rocq-runtime" ()

(** Set of packages linked by default. *)
let default_packages =
  ["camltac.plugin.runtime";
   "camltac.plugin.api";
   "ppx_rocq.runtime"]
  @ rocq_packages

(** Set of modules open by default. *)
let default_open_modules =
  ["Api"; "Prelude"]

type output =
  { compiled_file: Build_file.t;
    dependencies: string list }

open Camltac_directives

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

type context =
  { alias_module: string option;
    dependencies: string list;
    modules_dirs: string list
  }

let empty_context =
  { alias_module = None;
    dependencies = [];
    modules_dirs = []
  }

let compile_with_directives
      ?(context = empty_context)
      ~(directives: Build_directives.t)
      mode (impl: Build_file.t) =
  let ( let* ) = Result.bind in
  let* pp = Preprocessors.combine directives.ppx in
  let ppx_runtime_deps = ppx_runtime_deps directives.ppx in
  let dependencies = ppx_runtime_deps @ directives.libraries in
  let* compiled_file =
    Ocamlfind.ocamlc
      ~packages:(dependencies @ context.dependencies @ default_packages)
      ~include_dirs:((Build_file.layout impl).modules :: context.modules_dirs)
      ~open_modules:(Option.List.cons context.alias_module default_open_modules)
      ~optimize:(`O3)
      ~extra_args:("-short-paths" :: directives.compiler_options)
      ~pp
      mode
      impl
  in Ok { compiled_file; dependencies }

let compile ?context mode impl =
  match Build_directives.get (Build_file.locate impl) with
  | Ok directives -> compile_with_directives ?context ~directives mode impl
  | Error _ as e -> e
