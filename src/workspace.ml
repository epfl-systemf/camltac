(** Physical workspace. *)

open Filesystem
open Filesystem.Path

(** {1 Workspace} *)

type t = Path.t (** Path to the [.camltac] directory. *)

let camltac_dir_name = ".camltac"
let sources_dir_name = "sources"
let build_dir_name   = "build"

let create ws =
  Filesystem.mkdir ws;
  Filesystem.mkdir (ws / sources_dir_name);
  Filesystem.mkdir (ws / build_dir_name)

let at path =
  let ws = path / camltac_dir_name in
  create ws;
  ws

(** {2 Path resolution} *)

let root ws = ws

let resolve path ws =
  ws / path
