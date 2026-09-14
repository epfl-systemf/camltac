(** Methods for saving build artifacts. *)

let (/) = Filename.concat

open Names

(* When possible, we create the [.camltac] directory next to the [.v] file Rocq
   is currently compiling, since it is more robust than using the current
   working directory. We fallback to the current working directory when using
   the toplevel. *)
let root_dir =
  let current_unit = Lib.library_dp () in
  let parent_path = Libnames.pop_dirpath current_unit in
  let using_toplevel = DirPath.is_empty parent_path in
  if using_toplevel then Sys.getcwd ()
  else
    match Loadpath.find_with_logical_path parent_path with
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

(** {1 Write methods} *)

let write ~file contents =
  Out_channel.with_open_text file (fun out_channel -> output_string out_channel contents)

let write_temp ~dir ~prefix contents =
  let file = Filename.temp_file ~temp_dir:dir prefix ".ml" in
  write ~file contents;
  file

let write_snippet contents =
  write_temp ~dir:snippets_dir ~prefix:"snippet" contents

let write_module contents =
  write_temp ~dir:modules_dir ~prefix:"camltac_module__" contents

let write_ppx_driver contents =
  write_temp ~dir:ppx_dir ~prefix:"ppx" contents
