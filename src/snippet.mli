(** Representation of OCaml snippets. *)

(** {1 Snippets} *)

(** A snippet is a string of OCaml code that is inside a Rocq file,
    obtained through the [ocaml:(…)] quotation. *)

(** Type of OCaml snippets. *)
type t = private { loc: Loc.t;
                   contents: string }

val make : loc:Loc.t -> string -> t
(** [make ~loc snippet] creates a snippet at the given location. *)

val loc : t -> Loc.t
(** [loc snippet] returns the location of the snippet. *)

val contents : t -> string
(** [contents snippet] returns the contents of the snippet. *)
