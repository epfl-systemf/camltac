(** This file wraps the OCaml compiler (ocamlc/ocamlopt), providing utilities
    to compile to shared libraries that can be dynlinked. *)

let () = Findlib.init ()

(** List of Rocq packages that are automatically linked in. *)
let rocq_packages = Findlib.list_packages' ~prefix:"rocq-runtime" ()

let run_command prog args =
  let command = Filename.quote_command prog args in
  let err = Sys.command command in
  if err = 0 then Ok () else Error err

(** Call the OCaml compiler with the given arguments, returning [Ok ()] if the
    compilation was successful, or [Error code] if the compilation failed. *)
let call_compiler args =
  let ocamlfind = Boot.Env.ocamlfind () in
  let compiler = if Dynlink.is_native then "ocamlopt" else "ocamlc" in
  run_command ocamlfind (compiler :: args)

(** Return the compilation arguments for the given [file]. *)
let compilation_args file out =
  [
    if Dynlink.is_native then "-shared" else "-c";
    "-package"; String.concat "," rocq_packages;
    "-package"; "camltac.plugin.runtime";
    "-package"; "camltac.plugin.api";
    "-package"; "ppx_rocq.runtime";
    "-linkall";
    "-open"; "Api";
    "-open"; "Prelude";
    "-O3";
    "-impl"; file;
    "-o"; out
  ]

let lowlevel_compile ?(extra_args = []) file =
  let out = Dynlink.adapt_filename (Filename.remove_extension file ^ ".cmo") in
  let args = compilation_args file out @ extra_args in
  match call_compiler args with
  | Ok () -> Ok out
  | Error err ->
     (* TODO: Capture OCaml compilation errors to avoid printing them, e.g., when using [Fail].
        This would be doable once https://github.com/ocaml/ocaml/pull/13766 is merged. *)
     Error err

let run_with_output cmd =
  let inp = Unix.open_process_in cmd in
  let r = In_channel.input_all inp in
  In_channel.close inp; r

let find_cmxa lib =
  let basedir = Findlib.package_directory lib in
  Filename.concat basedir (lib ^ ".cmxa")

(* Create a standalone PPX executable from the given list of preprocessors. *)
let build_combined_ppx ppx_list =
  match ppx_list with
  | [] ->
     (* In most cases, we don't use PPXes, so don't build anything. *)
     Ok "ppx_rocq"
  | _ ->
     let ppx_ml_main = Tempfile.with_content ~prefix:"ppx" ~suffix:".ml" {|let () = Ppxlib.Driver.standalone ()|} in
     let out = Filename.remove_extension ppx_ml_main ^ ".exe" in
     let ppx_cmxa = List.map find_cmxa ("ppx_rocq" :: ppx_list) in
     let args =
       [
         "-package"; "ppxlib";
         "-package"; "ppx_rocq";
         "-package"; String.concat "," ppx_list;
         "-linkpkg";
       ]
       @ ppx_cmxa
       @ [
         "-o"; out;
         "-impl";
         ppx_ml_main;
       ]
     in
     match call_compiler args with
     | Ok () -> Ok out
     | Error err -> Error err

(** Convert metadata from annotations to a list of arguments for the compiler. *)
let metadata_to_compiler_args (metadata: Metadata.metadata) =
  let translate_option option = String.split_on_char ' ' option in
  let translate_lib lib = ["-package"; lib] in
  let ppx_args =
    match build_combined_ppx metadata.ppx with
    | Ok ppx_prog -> ["-pp"; ppx_prog ^ " --use-compiler-pp"]
    | Error _ ->
       (* Fallback to only using ppx_rocq *)
       (* TODO: Raise an error? *)
       ["-pp"; "ppx_rocq --use-compiler-pp"]
  in
  List.concat
    [
      List.concat_map translate_option metadata.compiler_options;
      List.concat_map translate_lib metadata.libraries;
      ppx_args
    ]

let get_metadata file =
  let annotation_ppx = "ppx_camltac_annotations" in
  let metafile = Filename.remove_extension file ^ ".ml.meta" in
  let args =
    [
      "-output-metadata"; metafile;
      "-null"; (* do not output anything *)
      "-impl"; file;
    ]
  in
  match run_command annotation_ppx args with
  | Ok () -> Metadata.read metafile
  | Error err ->
     (* Conservatively return empty metadata *)
     (* TODO: Return an error? *)
     Metadata.empty

let compile file =
  let metadata = get_metadata file in
  (* Make sure that extra packages and PPXes are loaded in. *)
  Fl_dynload.load_packages metadata.libraries;
  let extra_args = metadata_to_compiler_args metadata in
  lowlevel_compile ~extra_args file
