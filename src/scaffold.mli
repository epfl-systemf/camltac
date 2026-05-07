(** Methods for constructing scaffolds over a snippet. *)

(** {1 Scaffolds} *)

(** A scaffold encapsulates a [Snippet.t] by wrapping it between
    initialization and finalization code, making sure that the snippet
    is self-contained and ready to be run. *)

type t
(** Type of scaffolds. *)

val make : Snippet.t -> t
(** [make snippet] creates a scaffold for the given snippet. *)

val wrap : before:string -> after:string -> t -> t
(** [wrap ~before ~after scaffold] wraps the contents of the scaffold, adding
    [before] to the end of the initialization code and [after] to the start of
    the finalization code. *)

val contents : t -> string
(** [contents scaffold] returns the contents of the scaffold as a string. *)
