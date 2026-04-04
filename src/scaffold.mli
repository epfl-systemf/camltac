(** Methods for constructing scaffolds over a snippet. *)

(** {1 Scaffolds} *)

(** A scaffold encapsulates a [Snippet.t] by wrapping it between
    initialization and finalization code, making sure that the snippet
    is self-contained and ready to be run. *)

(** Type of scaffolds. *)
type t

(** Create a scaffold for the given snippet. *)
val make : Snippet.t -> t

(** Wrap the main content of the scaffold, adding [before] to the end of
    the initialization code and [after] to the start of the finalization
    code. *)
val wrap : before:string -> after:string -> t -> t

(** Return the contents of the scaffold as a string. *)
val contents : t -> string
