(** Methods for saving build artifacts. *)

let (/) = Filename.concat

let build_dir = Sys.getcwd () / ".camltac"
let snippets_dir = build_dir / "snippets"
let modules_dir = build_dir / "modules"
let ppx_dir = build_dir / "ppx"

(* Make sure that build directories exist. *)
let () =
  let mkdir dir = if not (Sys.file_exists dir) then Sys.mkdir dir 0o700 in
  mkdir build_dir;
  mkdir snippets_dir;
  mkdir modules_dir;
  mkdir ppx_dir

let save ~file contents =
  Out_channel.with_open_text file (fun out_channel -> output_string out_channel contents)

let save_temp ~dir ~prefix contents =
  let file = Filename.temp_file ~temp_dir:dir prefix ".ml" in
  save ~file contents;
  file

let save_snippet contents =
  save_temp ~dir:snippets_dir ~prefix:"snippet" contents

let remove_module name =
  let remove ext =
    let filename = modules_dir / name ^ ext in
    if Sys.file_exists filename then Sys.remove filename
  in
  remove ".ml";
  remove ".mli";
  remove ".cmo";
  remove ".cma";
  remove ".cmi";
  remove ".cmx";
  remove ".cmxa";
  remove ".cmxs"

let save_module contents =
  save_temp ~dir:modules_dir ~prefix:"camltac_module__" contents

let save_ppx_driver contents =
  save_temp ~dir:ppx_dir ~prefix:"ppx" contents
