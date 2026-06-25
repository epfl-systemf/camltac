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

let compile ?packing_module ~(directives: Build_directives.t) ?(infer_interface = false) impl =
  let ( let* ) = Result.bind in
  let* pp = Preprocessors.combine directives.ppx in
  (* Obtain shorter filenames. *)
  let impl = relativize ~dir:(Sys.getcwd () ^ "/") impl in
  let* compiled_file =
    Ocamlfind.compile
      ~shared:true
      ~packages:(directives.libraries @ default_packages)
      ~linkall:true
      ~include_dirs:[Build_files.modules_dir]
      ~open_modules:(Option.List.cons packing_module default_open_modules)
      ~optimize:(`O3)
      ~extra_args:("-short-paths" :: directives.compiler_options)
      ~infer_interface
      ~pp
      impl
  in Ok { compiled_file; dependencies = directives.libraries }

let compile_with_directives ?packing_module impl =
  match Build_directives.get impl with
  | Ok directives -> compile ?packing_module ~directives impl
  | Error _ as e -> e

let infer_interface ?packing_module impl =
  match Build_directives.get impl with
  | Ok directives -> compile ?packing_module ~directives ~infer_interface:true impl
  | Error _ as e -> e
