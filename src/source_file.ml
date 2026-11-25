(** OCaml source files. *)

open Filesystem.Path

[%%if rocq >= (9, 4)]
open Summary.Ref
[%%endif]

(** {1 Source file} *)

type t =
  { rocq_file: string; (** Name of the Rocq file. *)
    id: int;           (** Position of the snippet in the Rocq file. *)
    name: string;      (** Name of the source file. *)
  }

let id_counter =
  Summary.ref
    ~stage:Synterp
    ~name:"Camltac:SOURCE-FILE"
    0

let fresh_id () =
  let n = !id_counter in
  id_counter := n + 1;
  n

let fresh_source ~file =
  let id = fresh_id () in
  { id; rocq_file = file; name = Format.sprintf "%s_%d.ml" file id  }

let path { id; rocq_file; name } =
  rocq_file / string_of_int id / name

let resolve ~workspace source =
  Workspace.resolve (Workspace.sources_dir_name / path source) workspace

let create ~workspace ~file contents =
  let source = fresh_source ~file in
  let file = resolve ~workspace source in
  Filesystem.mkdir ~p:true (Filename.dirname file);
  Filesystem.write ~file contents;
  source
