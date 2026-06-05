(** Support for build directives related to preprocessors. *)

val combine : string list -> (string, int) result
(** [combine preprocessors] creates a preprocessor executable that
    runs each preprocessor simultaneously, similar to Dune's handling
    of the [preprocess] field. *)
