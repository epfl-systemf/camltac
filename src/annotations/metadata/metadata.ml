(** Definition and loading of metadata. *)

open Sexplib
open Sexplib.Std

type metadata = {
  compiler_options: string list [@default []];
  ppx             : string list [@default []];
  libraries       : string list [@default []];
} [@@deriving sexp] [@@sexp.allow_extra_fields]

let empty = { compiler_options = []; ppx = []; libraries = [] }

(** Read and parse preprocessing metadata from the given output file. *)
let read output_file =
  try
    let sexps = Sexp.load_sexps output_file in
    metadata_of_sexp (Sexp.List sexps)
  with _ ->
    empty
