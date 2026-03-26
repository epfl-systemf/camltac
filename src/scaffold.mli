(** Methods for constructing the scaffold over a snippet. *)

(** Type of scaffolds. *)
type t

(** Create a scaffold with the given content. *)
val make : ?loc:Loc.t -> string -> t

(** Wraps the main content of the scaffold with [before] and [after]. *)
val wrap : before:string -> after:string -> t -> t

(** Returns the content of the scaffold as a string. *)
val contents : t -> string
