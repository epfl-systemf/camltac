open Pp

(** Checks that the argument [file] can be loaded. *)
let check_file file =
  if not (Sys.file_exists file) then
    CErrors.user_err (str "File " ++ str file ++ str " does not exists.")

(** List of packages included when linking.
    TODO: Obtain this list through ocamlfind list | grep ^rocq-* *)
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

(** Compile the given file to a shared library. *)
let compile file =
  (* TODO: Load libraries specified through Dune. *)
  let out = Dynlink.adapt_filename "./temp.cmxs" in
  let prog = Boot.Env.ocamlfind () in
  let args = [
      "opt";
      "-shared";
      "-package";
      String.concat "," rocq_packages;
      "-o";
      out;
      file ] in
  let command = Filename.quote_command prog args in
  out, Sys.command command

(** Dynlink the given cmxs file. *)
let dynlink cmxs =
  try
    Dynlink.loadfile_private cmxs
  with Dynlink.Error e ->
    let message = Dynlink.error_message e in
    CErrors.user_err (str message)

let load_file file =
  (* Assume that the file path is absolute. *)
  check_file file;
  Feedback.msg_info (str "Loading file " ++ str file ++ str ".");
  let out, error = compile file in
  if error != 0 then
    CErrors.user_err (str "Compilation exited with error code " ++ int error ++ str ".")
  else
    dynlink out;
    Sys.remove out

