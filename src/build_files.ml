(** Methods for saving build artifacts. *)

let (/) = Filename.concat

let build_dir = Sys.getcwd () / ".camltac"
let snippets_dir = build_dir / "snippets"
let modules_dir = build_dir / "modules"
let ppx_dir = build_dir / "ppx"

(* Make sure that build directories exist. *)
let () =
  (if not (Sys.file_exists build_dir) then Sys.mkdir build_dir 0o700);
  (if not (Sys.file_exists snippets_dir) then Sys.mkdir snippets_dir 0o700);
  (if not (Sys.file_exists modules_dir) then Sys.mkdir modules_dir 0o700);
  (if not (Sys.file_exists ppx_dir) then Sys.mkdir ppx_dir 0o700)

let save ~file contents =
  Out_channel.with_open_text file (fun out_channel -> output_string out_channel contents)

let save_temp ~dir ~prefix contents =
  let file = Filename.temp_file ~temp_dir:dir prefix ".ml" in
  save ~file contents;
  file

let save_snippet contents =
  save_temp ~dir:snippets_dir ~prefix:"snippet" contents

let save_module ~name contents =
  assert (Char.Ascii.is_upper @@ String.get name 0);
  let file = modules_dir / name ^ ".ml" in
  match Sys.file_exists file with
  | true -> Error (Format.sprintf "Module %S already exists." name)
  | false -> save ~file contents; Ok file

let save_ppx_driver contents =
  save_temp ~dir:ppx_dir ~prefix:"ppx" contents
