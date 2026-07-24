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
  ["Api"; "Prelude"; "Prelude.Stdlib"]

(** Relativize [filename] against [dir]. *)
let relativize ~dir filename =
  if String.starts_with ~prefix:dir filename then
    let dirname_length = String.length dir in
    String.sub filename dirname_length (String.length filename - dirname_length)
  else
    filename

type output =
  { compiled_file: string;
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
  { packing_module: string option;
    loaded_dependencies: string list;
  }

let empty_context =
  { packing_module = None;
    loaded_dependencies = [] }

let compile ?(context = empty_context) ~(directives: Build_directives.t) ?(infer_interface = false) impl =
  let ( let* ) = Result.bind in
  let* pp = Preprocessors.combine directives.ppx in
  let ppx_runtime_deps = ppx_runtime_deps directives.ppx in
  let dependencies = ppx_runtime_deps @ directives.libraries in
  (* Obtain shorter filenames. *)
  let impl = relativize ~dir:(Sys.getcwd () ^ "/") impl in
  let* compiled_file =
    Ocamlfind.compile
      ~shared:true
      ~packages:(dependencies @ context.loaded_dependencies @ default_packages)
      ~linkall:true
      ~include_dirs:[Build_files.modules_dir]
      ~open_modules:(Option.List.cons context.packing_module default_open_modules)
      ~optimize:(`O3)
      ~extra_args:("-short-paths" :: "-nopervasives" :: directives.compiler_options)
      ~infer_interface
      ~pp
      impl
  in Ok { compiled_file; dependencies }

let compile_with_directives ?context impl =
  match Build_directives.get impl with
  | Ok directives -> compile ?context ~directives impl
  | Error _ as e -> e

let infer_interface ?context impl =
  match Build_directives.get impl with
  | Ok directives -> compile ?context ~directives ~infer_interface:true impl
  | Error _ as e -> e
