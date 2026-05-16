(** Methods for running and interacting with [ppx_rocq]. *)

(** Type of metadata obtained from preprocessing. *)
type metadata = {
  compiler_options: string list; (** List of compiler options. *)
  libraries: string list         (** List of libraries to link. *)
}

val preprocess : string -> (string * metadata, int) result
(** [preprocess file] runs the [ppx_rocq] preprocessor on the given file,
    returning the path to the preprocessed file along with its metadata on
    success, or the error code if preprocessing failed. *)
