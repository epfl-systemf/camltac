(** Methods for saving build artifacts. *)

let (/) = Filename.concat

let build_dir = Sys.getcwd () / ".camltac"
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

let save ~file contents =
  Out_channel.with_open_text file (fun out_channel -> output_string out_channel contents)

let save_temp ~dir ~prefix contents =
  let file = Filename.temp_file ~temp_dir:dir prefix ".ml" in
  save ~file contents;
  file

let save_snippet contents =
  save_temp ~dir:snippets_dir ~prefix:"snippet" contents

let save_module contents =
  save_temp ~dir:modules_dir ~prefix:"camltac_module__" contents

let save_ppx_driver contents =
  save_temp ~dir:ppx_dir ~prefix:"ppx" contents
