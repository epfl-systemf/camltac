(** Streams of characters. *)

open Ppxlib

type t =
  { contents: string; (** Contents of the stream. *)
    pos: position;    (** Current position of the stream inside the file. *)
    index: int;       (** Index of the current position in the stream contents. *)
    length: int;      (** Length of the stream. *)
  }

val of_string : loc:location -> string -> t
(** [of_string ~loc s] creates a stream of characters at the given location. *)

val is_empty : t -> bool
(** [is_empty stream] returns [true] if the stream has no more characters. *)

val advance : n:int -> t -> t
(** [advance ~n stream] consumes [n] characters of the stream. *)

val take : n:int -> t -> string
(** [take ~n stream] returns the next [n] characters of the stream. *)

val take_all : t -> string
(** [take_all stream] returns the rest of the stream as a string. *)

val span : pattern:string -> t -> string * t
(** [span ~pattern stream] return the prefix of [stream] until the first
    occurrence of [pattern], as well as the remaining stream. *)

val located_span : pattern:string -> t -> string loc * t
(** [located_span ~pattern stream] behaves like [span ~pattern stream], except
    that the prefix is located. *)
