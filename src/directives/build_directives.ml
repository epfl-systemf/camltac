(** Definition and parsing of build directives. *)

open Sexplib
open Sexplib.Std

(** Type of build directives. *)
type t = {
    compiler_options : string list [@default []];
    ppx              : string list [@default []];
    libraries        : string list [@default []]; (** A list of external libraries to use. *)
} [@@deriving sexp] [@@sexp.allow_extra_fields]

(** [empty] return empty build directives. *)
let empty =
  { compiler_options = [];
    ppx = [];
    libraries = [] }

let read_output output_file =
  let sexps = Sexp.load_sexps output_file in
  t_of_sexp (Sexp.List sexps)

let get file =
  let ppx_executable = "ppx_camltac_directives" in
  let output_file = Filename.remove_extension file ^ ".ml.meta" in
  let args =
    [
      "-output-metadata"; output_file;
      "-null"; (* Do not print anything on stdout *)
      "-impl"; file;
    ]
  in
  let cmd = Filename.quote_command ppx_executable args in
  match Sys.command cmd with
  | 0 -> Ok (read_output output_file)
  | err -> Error err
