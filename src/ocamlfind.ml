(** Methods wrapping the [ocamlfind] executable. *)

(** {1 Library management} *)

(** For this part, we use the [Findlib] API instead of the executable,
    because the API directly returns structured output. This might
    hypothetically lead to incoherencies however. *)

let () = Findlib.init ()

let list_packages ?prefix () =
  Findlib.list_packages' ?prefix ()

(** {1 Compilation} *)

(** {2 Arguments} *)

let add_argument ~if_ arg args =
  if if_ then arg :: args else args

let add_arguments name list acc =
  let[@tail_mod_cons] rec add = function
    | [] -> acc
    | arg :: args -> name :: arg :: add args
  in
  add list

let output_extension ~stop_after ~shared ~native =
  match stop_after with
  | Some `typing -> ".cmi"
  |_ ->
    match shared, native with
    | true, true -> ".cmxs"
    | true, false -> ".cma"
    | false, true -> ".cmx"
    | false, false -> ".cmo"

(* Obtain shorter filenames for better error messages. *)
let shorten_filename impl =
  let prefix = Sys.getcwd () ^ "/" in
  if String.starts_with ~prefix impl then
    let prefix_length = String.length prefix in
    String.sub impl prefix_length (String.length impl - prefix_length)
  else
    impl

let native = Dynlink.is_native

let compilation_args
      ~packages ~linkpkg ~linkall
      ~compile_only
      ~shared
      ~include_dirs
      ~open_modules
      ~extra_args
      ?optimize
      ~pp
      ?stop_after
      ~infer_interface
      ?out impl =
  let impl = Build_files.locate impl in
  let impl = shorten_filename impl in
  let args = ["-impl"; impl] in
  let out =
    match out with
    | Some out -> out
    | None ->
       let out_extension = output_extension ~stop_after ~shared ~native in
       Filename.remove_extension impl ^ out_extension
  in
  let args = if not infer_interface then ["-o"; out] @ args else args in
  let args =
    match stop_after with
    | Some `parsing -> ["-stop-after"; "parsing"] @ args
    | Some `typing -> ["-stop-after"; "typing"] @ args
    | Some `lambda -> ["-stop-after"; "lambda"] @ args
    | _ -> args
  in
  let args =
    match optimize with
    | Some `O2 when native -> "-O2" :: args
    | Some `O3 when native -> "-O3" :: args
    | _ -> args
  in
  let args = ["-pp"; pp ^ " -as-pp --use-compiler-pp --cookie ppx_rocq.camltac_mode=true"] @ args in
  let args = extra_args @ args in
  let args = add_arguments "-open" open_modules args in
  let args = add_arguments "-I" include_dirs args in
  let args = add_argument ~if_:linkall "-linkall" args in
  let args = add_argument ~if_:linkpkg "-linkpkg" args in
  let args = add_arguments "-package" packages args in
  let args = add_argument ~if_:(shared && not infer_interface) (if native then "-shared" else "-a") args in
  let args = add_argument ~if_:compile_only "-c" args in
  let args = add_argument ~if_:infer_interface "-i" args in
  args, Build_files.of_path out

(** {2 Calling the compiler} *)

[%%if rocq >= (9, 1)]
let ocamlfind () = Boot.Env.ocamlfind ()
[%%else]
let ocamlfind () = Envars.ocamlfind ()
[%%endif]

let run_command ?stdout prog args =
  let command = Filename.quote_command prog ?stdout args in
  let err = Sys.command command in
  if err = 0 then Ok () else Error err

let run_ocamlfind ?stdout args =
  run_command ?stdout (ocamlfind ()) args

let compiler = if Dynlink.is_native then "ocamlopt" else "ocamlc"

let compile
      ?(packages = []) ?(linkall = false)
      ?(compile_only = false)
      ?(shared = false)
      ?(include_dirs = [])
      ?(open_modules = [])
      ?optimize
      ?(extra_args = [])
      ?(pp = "ppx_rocq")
      ?stop_after
      ?out impl =
  let args, out =
    compilation_args
      ~packages ~linkpkg:false ~linkall
      ~compile_only
      ~shared
      ~include_dirs
      ~open_modules
      ~extra_args
      ?optimize
      ~pp
      ?stop_after
      ~infer_interface:false
      ?out
      impl
  in
  match run_ocamlfind (compiler :: args) with
  | Ok () -> Ok out
  | Error _ as e ->
     (* TODO: Capture OCaml compilation errors instead of printing them to integrate with [Fail].
        This would be doable once https://github.com/ocaml/ocaml/pull/13766 is merged. *)
     e

let compile_exe
      ?(packages = []) ?(linkpkg = false) ?(linkall = false)
      ?(include_dirs = [])
      ?(open_modules = [])
      ?optimize
      ?(extra_args = [])
      ?(pp = "ppx_rocq")
      impl =
  let out = Filename.remove_extension (Build_files.locate impl) ^ ".exe" in
  let args, out =
    compilation_args
      ~packages ~linkpkg ~linkall
      ~compile_only:false
      ~shared:false
      ~include_dirs
      ~open_modules
      ~extra_args
      ?optimize
      ~pp
      ~infer_interface:false
      ~out
      impl
  in
  match run_ocamlfind (compiler :: args) with
  | Ok () -> Ok out
  | Error _ as e ->
     (* TODO: Capture OCaml compilation errors instead of printing them to integrate with [Fail].
        This would be doable once https://github.com/ocaml/ocaml/pull/13766 is merged. *)
     e

let infer_interface
      ?(packages = [])
      ?(include_dirs = [])
      ?(open_modules = [])
      ?(extra_args = [])
      ?(pp = "ppx_rocq")
      impl =
  let stdout = Filename.remove_extension (Build_files.locate impl) ^ ".check.mli" in
  let args, out =
    compilation_args
      ~packages ~linkpkg:false ~linkall:false
      ~compile_only:false
      ~shared:false
      ~include_dirs
      ~open_modules
      ~extra_args
      ~pp
      ~infer_interface:true
      ~out:stdout
      impl
  in
  match run_ocamlfind ~stdout (compiler :: args) with
  | Ok () -> Ok out
  | Error _ as e ->
     (* TODO: Capture OCaml compilation errors instead of printing them to integrate with [Fail].
        This would be doable once https://github.com/ocaml/ocaml/pull/13766 is merged. *)
     e
