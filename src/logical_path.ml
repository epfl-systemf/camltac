(** Logical paths. *)

open Names

(** {1 Logical paths} *)

type t =
  { root: DirPath.t;          (** Root of the logical path. *)
    path: CUnix.physical_path (** Path relative to the root's physical location. *)
  }

let make root path = { root; path }

let root logical_path = logical_path.root
let path logical_path = logical_path.path

let of_build_file (file: Build_file.t) =
  let root =
    Build_file.root file
    |> Loadpath.find_load_path
    |> Loadpath.logical
  in
  { root; path = Build_file.relative_path file }

let to_build_file (logical: t) =
  let absolute_path =
    Loadpath.find_extra_dep_with_logical_path
      ~from:logical.root
      ~file:logical.path
      ()
  in
  let root =
    String.sub absolute_path
      0
      (String.length absolute_path - String.length logical.path - 1)
  in
  Build_file.unsafe_of_path ~root logical.path
