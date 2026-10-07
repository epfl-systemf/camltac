(** Build artifacts. *)

(** {1 Build files} *)

type t =
  { root: Layout.root;        (** Root of the layout. *)
    path: CUnix.physical_path (** Path relative to [root]. *)
  }

let layout file = Layout.of_root file.root
let locate file = Layout.resolve file.root file.path
let path file = Layout.path file.root file.path

let with_extension file ext =
  { file with path = Filename.remove_extension file.path ^ ext }

let module_name build_file =
  File.module_name build_file.path

(** {1 Creation} *)

type kind = Snippet | Module | Ppx_driver

let kind_dir = function
  | Snippet -> (Layout.current ()).snippets
  | Module -> (Layout.current ()).modules
  | Ppx_driver -> (Layout.current ()).ppx

let kind_prefix = function
  | Snippet -> "snippet"
  | Module -> "camltac_module__"
  | Ppx_driver -> "ppx"

let (/) = Filename.concat

let write_temp ~dir ~prefix contents =
  let file = Filename.temp_file ~temp_dir:dir prefix ".ml" in
  File.write ~file contents;
  { root = Layout.current_root ();
    path = ".camltac" / Filename.basename dir / Filename.basename file }

let write ~kind contents =
  let dir = kind_dir kind in
  let prefix = kind_prefix kind in
  write_temp ~dir ~prefix contents
