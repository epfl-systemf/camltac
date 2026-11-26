(** Build artifacts. *)

(** {1 Build files} *)

type t =
  { root: CUnix.physical_path; (** Root of the layout. *)
    path: CUnix.physical_path  (** Path relative to [root]. *)
  }

let (/) = Filename.concat

let unsafe_of_path ~root path = { root; path }

let root file = file.root
let relative_path file = file.path

let layout file = Layout.of_root file.root
let path file = file.root / file.path

let locate file =
  let path = path file in
  if Sys.file_exists path then
    path
  else
    CErrors.user_err (Pp.(str "File " ++ str file.path ++ str " not found in " ++ str file.root))

let with_extension file ext =
  { file with path = Filename.remove_extension file.path ^ ext }

let module_name build_file =
  Filesystem.Path.module_name build_file.path

(** {1 Read/write} *)

let read file = Filesystem.read (locate file)

type kind = Snippet | Module | Ppx_driver

let kind_dir ~(layout: Layout.t) = function
  | Snippet -> layout.snippets
  | Module -> layout.modules
  | Ppx_driver -> layout.ppx

let kind_prefix = function
  | Snippet -> "snippet"
  | Module -> "camltac_module__"
  | Ppx_driver -> "ppx"

let write_temp ~dir ~prefix contents =
  let file = Filename.temp_file ~temp_dir:dir prefix ".ml" in
  Filesystem.write ~file contents;
  file

let write ~kind contents =
  let layout = Layout.current () in
  let dir = kind_dir ~layout kind in
  let prefix = kind_prefix kind in
  let file = write_temp ~dir ~prefix contents in
  { root = layout.root;
    path = Filesystem.Path.relativize_if_under ~dir:layout.root file }
