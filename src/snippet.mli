(** Representation of OCaml snippets. *)

(** {1 Snippets} *)

(** A snippet is a string of OCaml code that is inside a Rocq file,
    obtained through the [ocaml:(…)] quotation. *)

type t
(** Type of OCaml snippets. *)

(** {2 Constructors} *)

val make : loc:Loc.t -> string -> t
(** [make ~loc contents] creates a snippet with the given contents. *)

val of_file : loc:Loc.t -> string -> t
(** [of_file ~loc filename] creates a snippet for the given file. *)

(** {2 Getters} *)

val loc : t -> Loc.t
(** [loc snippet] returns the location of the snippet. *)

val contents : t -> string
(** [contents snippet] returns the contents of the snippet. *)

(** {2 Subsnippets} *)

val sub : lines:(int * int) -> chars:(int * int) -> t -> t
(** [sub ~lines ~chars snippet] returns the subsnippet that contains the given
    lines and characters. Both [lines] and [chars] must be included in the
    snippet location. *)
