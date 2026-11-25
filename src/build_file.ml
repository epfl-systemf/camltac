(** Build files. *)

open Filesystem
open Filesystem.Path

(** {1 Build files} *)

type t =
  { workspace: Workspace.t;   (** Workspace that includes the build file. *)
    path: Path.t (** Path relative to the workspace root. *)
  }

let unsafe_of_path ~workspace path =
  { workspace; path }

let workspace { workspace } = workspace
let path { path } = path

(** {2 Creating build files} *)

open Filesystem

let build_dir source =
  Workspace.build_dir_name / Filename.dirname (Source_file.path source)

let fresh_name ~prefix ~avoid =
  let n = ref 0 in
  let filename () = prefix ^ string_of_int !n ^ ".ml" in
  while CString.Set.mem (Path.module_name (filename ())) avoid do
    n := !n + 1
  done;
  filename ()

let build_filename ~avoid source =
  let prefix =
    (Source_file.path source
     |> Filename.basename
     |> Filename.remove_extension) ^ "__"
  in
  fresh_name ~prefix ~avoid

(** {3 Cleanup} *)

(* A plain ref that stores all previous build files created by this
   process. This avoids cleaning up other process' artifacts in case of
   concurrency. *)
let own_builds = ref CString.Set.empty

let is_stale ~keep file =
  let unit_name = Path.module_name file in
  CString.Set.mem unit_name !own_builds && not (CString.Set.mem unit_name keep)

let remove_old_builds ~dir ~keep =
  Sys.readdir dir
  |> Array.to_list
  |> List.filter (is_stale ~keep)
  |> List.iter (fun file -> Sys.remove (dir / file))

let copy_source ~workspace ~loaded_units (source: Source_file.t) =
  let dir = build_dir source in
  let absolute_dir = Workspace.resolve dir workspace in
  Filesystem.mkdir ~p:true absolute_dir;
  remove_old_builds ~dir:absolute_dir ~keep:loaded_units;
  let filename = build_filename ~avoid:loaded_units source in
  Filesystem.write
    ~file:(absolute_dir / filename)
    (Filesystem.read (Source_file.resolve ~workspace source));
  own_builds := CString.Set.add (Path.module_name filename) !own_builds;
  { workspace; path = dir / filename }

let generate ~workspace ~dir ~name contents =
  let dir = Workspace.build_dir_name / dir in
  let absolute_dir = Workspace.resolve dir workspace in
  Filesystem.mkdir ~p:true absolute_dir;
  Filesystem.write ~file:(absolute_dir / name) contents;
  { workspace; path = dir / name }

let with_extension ext file =
  { file with path = Filename.remove_extension file.path ^ ext }

(** {2 Path resolution} *)

let resolve (file: t) =
  Workspace.resolve file.path file.workspace
