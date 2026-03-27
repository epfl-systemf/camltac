(** Representation of OCaml snippets. *)

(** {1 Snippets} *)

(** A snippet is a string of OCaml code that is inside a Rocq file,
    obtained through the [ocaml:(…)] quotation.

    Contrary to standalone OCaml files, snippets are executed inside a
    Rocq context, and therefore can interact or modify it. *)

(** Type of OCaml snippets. *)
type t = private { loc: Loc.t;
                   contents: string }

(** [make ~loc snippet] creates a snippet that comes with the given
    location information. *)
val make : loc:Loc.t -> string -> t

(** [loc snippet] returns the location of the snippet. *)
val loc : t -> Loc.t

(** [contents snippet] returns the contents of the snippet. *)
val contents : t -> string
