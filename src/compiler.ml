(** This file wraps the OCaml compiler (ocamlc & ocamlopt),
    providing utilities to compile to shared libraries that can be dynlinked. *)


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

(** Call the OCaml compiler with the given arguments, returning [Ok ()] if the
    compilation was successful, or [Error code] if the compilation failed. *)
let call_compiler args =
  let ocamlfind = Boot.Env.ocamlfind () in
  let compiler = if Dynlink.is_native then "ocamlopt" else "ocamlc" in
  let command = Filename.quote_command ocamlfind (compiler :: args) in
  let err = Sys.command command in
  if err = 0 then Ok () else Error err

(** Return the compilation arguments for the given [file]. *)
let compilation_args file out =
  [
    if Dynlink.is_native then "-shared" else "-c";
    "-package";
    String.concat "," rocq_packages;
    "-package";
    "mltac.plugin.runtime";
    "-O2";
    "-o";
    out;
    "-impl";
    file
  ]


let compile file =
  let out = Dynlink.adapt_filename (Filename.remove_extension file ^ ".cmo") in
  let args = compilation_args file out in
  match call_compiler args with
  | Ok () -> Ok out
  | Error err -> Error err
