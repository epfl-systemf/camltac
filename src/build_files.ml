(** Methods for saving build artifacts. *)

open Names

(** {1 Build directories} *)

let (/) = Filename.concat

(* When possible, we create the [.camltac] directory next to the [.v] file Rocq
   is currently compiling, since it is more robust than using the current
   working directory. We fallback to the current working directory when using
   the toplevel. *)
let root_path = Libnames.pop_dirpath (Lib.library_dp ())

let root_dir =
  let using_toplevel = DirPath.is_empty root_path in
  if using_toplevel then
    (* IMPORTANT: The mapping <> -> Sys.getcwd () is in the loadpath. *)
    Sys.getcwd ()
  else
    match Loadpath.find_with_logical_path root_path with
    | [load_path] -> Loadpath.physical load_path
    | _ -> assert false

let build_dir = root_dir / ".camltac"
let snippets_dir = build_dir / "snippets"
let modules_dir = build_dir / "modules"
let ppx_dir = build_dir / "ppx"

(* Make sure that build directories exist. *)
let () =
  let mkdir dir =
    try Sys.mkdir dir 0o700
    with Sys_error _ when Sys.file_exists dir -> ()
  in
  mkdir build_dir;
  mkdir snippets_dir;
  mkdir modules_dir;
  mkdir ppx_dir

(** {1 Build files} *)

type t =
  { from: DirPath.t;          (** Logical path where the build file was originally created. *)
    path: CUnix.physical_path (** Path relative to [from]. *)
  }

let of_path path =
  let absolute_path = if Filename.is_implicit path then Filename.concat (Sys.getcwd ()) path else path in
  let prefix = root_dir ^ "/" in
  if String.starts_with ~prefix absolute_path then
    let prefix_length = String.length prefix in
    { from = root_path;
      path = String.sub absolute_path prefix_length (String.length absolute_path - prefix_length) }
  else
    invalid_arg (Format.sprintf "%s is not a build file." path)

let module_name build_file =
  Filename.basename build_file.path
  |> Filename.remove_extension
  |> String.capitalize_ascii

let locate build_file =
  if DirPath.equal build_file.from root_path then
    (* Build layout. *)
    Filename.concat root_dir build_file.path
  else
    (* Install layout. *)
    Loadpath.find_extra_dep_with_logical_path
      ~from:build_file.from
      ~file:build_file.path
      ()

let build_dir ?file () =
  match file with
  | Some file -> locate { file with path = ".camltac" }
  | None -> build_dir

let modules_dir ?file () =
  Filename.concat (build_dir ?file ()) "modules"

type kind = Snippet | Module | Ppx_driver

let write_temp ~dir ~prefix contents =
  let file = Filename.temp_file ~temp_dir:dir prefix ".ml" in
  File.write ~file contents;
  of_path file

let kind_dir = function
  | Snippet -> snippets_dir
  | Module -> modules_dir ()
  | Ppx_driver -> ppx_dir

let kind_prefix = function
  | Snippet -> "snippet"
  | Module -> "camltac_module__"
  | Ppx_driver -> "ppx"

let write kind contents =
  let dir = kind_dir kind in
  let prefix = kind_prefix kind in
  write_temp ~dir ~prefix contents
