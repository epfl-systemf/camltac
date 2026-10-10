(** Methods wrapping the [ocamlfind] executable. *)

(** {1 Library management} *)

(** For this part, we use the [Findlib] API instead of the executable,
    because the API directly returns structured output. This might
    hypothetically lead to incoherencies however. *)

let () = Findlib.init ()

let list_packages ?prefix () =
  Findlib.list_packages' ?prefix ()

let packages = lazy (list_packages ())

let package_exists name =
  let packages = Lazy.force packages in
  if List.mem name packages then
    Ok ()
  else
    (* TODO: Add suggestion using spellcheck (OCaml 5.4). *)
    let suggestion = None in
    Error suggestion

(** {1 Compilation} *)

(** {2 Arguments} *)

type mode =
  | Shared_library of { linkall: bool }
  | Executable of { linkall: bool; linkpkg: bool }
  | Compile_only
  | Infer_interface

let output_extension mode ~native =
  match mode, native with
  | Shared_library _, true  -> ".cmxs"
  | Shared_library _, false -> ".cma"
  | Executable _    , _     -> ".exe"
  | Compile_only    , true  -> ".cmx"
  | Compile_only    , false -> ".cmo"
  | Infer_interface , _     -> ".check.mli"

let arguments name list =
  let[@tail_mod_cons] rec loop = function
    | [] -> []
    | arg :: args -> name :: arg :: loop args
  in
  loop list

let compilation_args
      ~native
      ~packages
      ~include_dirs ~open_modules
      ?optimize
      ~pp
      ~extra_args
      mode
      impl =
  let out = Build_file.with_extension impl (output_extension mode ~native) in
  let args =
     (match mode, native with
      | Shared_library _, true  -> ["-shared"]
      | Shared_library _, false -> ["-a"]
      | Executable _    , _     -> []
      | Compile_only    , _     -> ["-c"]
      | Infer_interface , _     -> ["-i"])
    @ ["-impl"; File.relativize_if_under (Build_file.locate impl)]
    @ (if mode <> Infer_interface then ["-o"; Build_file.path out] else [])
    @ (match optimize, native with
      | Some `O2, true -> ["-O2"]
      | Some `O3, true -> ["-O3"]
      | _       , _    -> [])
    @ arguments "-package" packages
    @ arguments "-I" include_dirs
    @ arguments "-open" open_modules
    @ ["-pp"; Filename.quote pp ^ " -as-pp --use-compiler-pp --cookie ppx_rocq.camltac_mode=true"]
    @ (match mode with
      | Shared_library { linkall = true }
      | Executable { linkall = true; _ } -> ["-linkall"]
      | _                                -> [])
    @ (match mode with
      | Executable { linkpkg = true; _ } -> ["-linkpkg"]
      | _                                -> [])
    @ extra_args
  in
  args, out

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

let ocamlc
      ?(native = Dynlink.is_native)
      ?(packages = [])
      ?(include_dirs = [])
      ?(open_modules = [])
      ?optimize
      ?(pp = "ppx_rocq")
      ?(extra_args = [])
      mode impl =
  let compiler = if native then "ocamlopt" else "ocamlc" in
  let args, out =
    compilation_args
      ~native
      ~packages
      ~include_dirs
      ~open_modules
      ?optimize
      ~pp
      ~extra_args
      mode impl
  in
  (* The output of [Infer_interface] is printed on the standard output. *)
  let stdout =
    match mode with
    | Infer_interface -> Some (Build_file.path out)
    | _ -> None
  in
  match run_ocamlfind ?stdout (compiler :: args) with
  | Ok () -> Ok out
  | Error _ as e ->
     (* TODO: Capture OCaml compilation errors instead of printing them to integrate with [Fail].
        This would be doable once https://github.com/ocaml/ocaml/pull/13766 is merged. *)
     e
