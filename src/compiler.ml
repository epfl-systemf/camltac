(** This file wraps the OCaml compiler (ocamlc/ocamlopt), providing utilities
    to compile to shared libraries that can be dynlinked. *)


(** List of Rocq packages that are automatically linked in.

    TODO: Obtain this list through [ocamlfind list | grep ^rocq-*]. *)
let rocq_packages = [
    "rocq-core";
    "rocq-runtime";
    "rocq-runtime.boot";
    "rocq-runtime.checklib";
    "rocq-runtime.clib";
    "rocq-runtime.config";
    "rocq-runtime.config.byte";
    "rocq-runtime.coqargs";
    "rocq-runtime.coqdeplib";
    "rocq-runtime.coqworkmgrapi";
    "rocq-runtime.debugger_support";
    "rocq-runtime.engine";
    "rocq-runtime.gramlib";
    "rocq-runtime.interp";
    "rocq-runtime.kernel";
    "rocq-runtime.lib";
    "rocq-runtime.library";
    "rocq-runtime.parsing";
    "rocq-runtime.perf";
    "rocq-runtime.plugins";
    "rocq-runtime.plugins.btauto";
    "rocq-runtime.plugins.cc";
    "rocq-runtime.plugins.cc_core";
    "rocq-runtime.plugins.derive";
    "rocq-runtime.plugins.extraction";
    "rocq-runtime.plugins.firstorder";
    "rocq-runtime.plugins.firstorder_core";
    "rocq-runtime.plugins.funind";
    "rocq-runtime.plugins.ltac";
    "rocq-runtime.plugins.ltac2";
    "rocq-runtime.plugins.ltac2_ltac1";
    "rocq-runtime.plugins.micromega";
    "rocq-runtime.plugins.micromega_core";
    "rocq-runtime.plugins.nsatz";
    "rocq-runtime.plugins.nsatz_core";
    "rocq-runtime.plugins.number_string_notation";
    "rocq-runtime.plugins.ring";
    "rocq-runtime.plugins.rtauto";
    "rocq-runtime.plugins.ssreflect";
    "rocq-runtime.plugins.ssrmatching";
    "rocq-runtime.plugins.tauto";
    "rocq-runtime.plugins.zify";
    "rocq-runtime.pretyping";
    "rocq-runtime.printing";
    "rocq-runtime.proofs";
    "rocq-runtime.rocqshim";
    "rocq-runtime.stm";
    "rocq-runtime.sysinit";
    "rocq-runtime.tactics";
    "rocq-runtime.toplevel";
    "rocq-runtime.vernac";
    "rocq-runtime.vm";
]

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

(* Create a standalone PPX executable from the given list of preprocessors. *)
let build_combined_ppx ppx_list =
  match ppx_list with
  | [] ->
     (* In most cases, we don't use PPXes, so don't build anything. *)
     Ok "ppx_rocq -as-ppx"
  | _ ->
     let ppx_ml_main = Tempfile.with_content ~prefix:"ppx" ~suffix:".ml" {|let () = Ppxlib.Driver.run_as_ppx_rewriter ()|} in
     let out = Filename.remove_extension ppx_ml_main ^ ".exe" in
     let args =
       [
         "-package"; "ppxlib";
         "-package"; "ppx_rocq";
         "-package"; String.concat "," ppx_list;
         "-linkpkg";
         "-linkall";
         "-o"; out;
         "-only-show";
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
    | Ok ppx_prog -> ["-ppx"; ppx_prog]
    | Error _ ->
       (* Fallback to only using ppx_rocq *)
       (* TODO: Raise an error? *)
       ["-ppx"; "ppx_rocq -as-ppx"]
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
  Fl_dynload.load_packages metadata.ppx;
  let extra_args = metadata_to_compiler_args metadata in
  lowlevel_compile ~extra_args file
