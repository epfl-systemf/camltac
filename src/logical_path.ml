(** Logical paths. *)

open Filesystem
open Names

(** {1 Logical paths} *)

type t =
  { root: DirPath.t; (** Root of the logical path. *)
    path: Path.t     (** Path relative to the logical path's workspace. *)
  }

let make root path = { root; path }

let root logical_path = logical_path.root
let path logical_path = logical_path.path

let of_build_file (file: Build_file.t) =
  let root =
    Build_file.workspace file
    |> Workspace.root
    |> Filename.dirname
    |> Loadpath.find_load_path
    |> Loadpath.logical
  in
  { root; path = Build_file.path file }

let to_build_file (logical: t) =
  let open Path in
  let relative_path = Workspace.camltac_dir_name / logical.path in
  let absolute_path =
    Loadpath.find_extra_dep_with_logical_path
      ~from:logical.root
      ~file:relative_path
      ()
  in
  let root =
    String.sub absolute_path
      0
      (String.length absolute_path - String.length relative_path)
  in
  Build_file.unsafe_of_path ~workspace:(Workspace.at root) logical.path
