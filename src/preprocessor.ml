(** Methods for running and interacting with [ppx_rocq]. *)

(** {1 Metadata} *)

open Sexplib.Std

type metadata = {
  compiler_options: string list [@default []];
  libraries       : string list [@default []]
} [@@deriving sexp] [@@sexp.allow_extra_fields]

(** Read and parse preprocessing metadata from the output file. *)
let read_preprocessing_metadata file =
  let open Sexplib in
  try
    let sexps = Sexp.load_sexps file in
    metadata_of_sexp (Sexp.List sexps)
  with _ ->
    { compiler_options = []; libraries = [] }

(** {1 Launching [ppx_rocq]} *)

(** List of arguments given to [ppx_rocq]. *)
let ppx_rocq_args input out meta =
  [
    (* TODO: Add [-loc-filename] *)
    "-as-pp";
    "-impl"; input;
    "-o"; out;
    "-output-metadata"; meta
  ]

let run_ppx args =
  let command = Filename.quote_command "ppx_rocq" args in
  let err = Sys.command command in
  if err = 0 then Ok () else Error err

let preprocess file =
  let out = Filename.remove_extension file ^ ".pp.ml" in
  let meta = Filename.remove_extension file ^ ".pp.meta" in
  let args = ppx_rocq_args file out meta in
  match run_ppx args with
  | Ok () ->
     let metadata = read_preprocessing_metadata meta in
     Ok (out, metadata)
  | Error err -> Error err
