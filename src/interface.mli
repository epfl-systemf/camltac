(** Parsing OCaml interfaces. *)

(** {1 Interfaces} *)

type t
(** Type of parsed interfaces. *)

val parse : string -> t
(** [parse intf] parses the interface [intf]. *)

val tactic_type : t -> (string, string) result
(** [tactic_type intf] returns [Ok typ] if [intf] is [val __x : typ tactic],
    or [Error typ] otherwise. *)

val print : t -> Pp.t
(** [print intf] pretty-prints the interface. *)
