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

let kind_dir ~(layout: Layout.t) = function
  | Snippet -> layout.snippets
  | Module -> layout.modules
  | Ppx_driver -> layout.ppx

let kind_prefix = function
  | Snippet -> "snippet"
  | Module -> "camltac_module__"
  | Ppx_driver -> "ppx"

let (/) = Filename.concat

let write_temp ~dir ~prefix contents =
  let file = Filename.temp_file ~temp_dir:dir prefix ".ml" in
  File.write ~file contents;
  file

let write ~kind contents =
  let layout = Layout.current () in
  let dir = kind_dir ~layout kind in
  let prefix = kind_prefix kind in
  let file = write_temp ~dir ~prefix contents in
  { root = layout.root;
    path = Filename.dirname (File.relativize_if_under ~dir:layout.build file) }
