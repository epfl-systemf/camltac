(** Support for building custom preprocessors. *)

(** Type of preprocessors. *)
type t =
  | Default                (** Default preprocessor (i.e. [ppx_rocq]). *)
  | Custom of Build_file.t (** A custom preprocessor. *)

val create : string list -> (t, int) result
(** [create ppxs] creates a preprocessor executable that
    runs each preprocessor simultaneously, similar to Dune's handling
    of the [preprocess] field. *)
