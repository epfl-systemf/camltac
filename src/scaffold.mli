(** Methods for constructing scaffolds over a snippet. *)

(** {1 Scaffolds} *)

(** A scaffold encapsulates a [Snippet.t] by wrapping it between
    initialization and finalization code.

    Scaffolds are used to transform snippets before they run, adding
    the necessary boilerplate. *)

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
