(** Reading and parsing OCaml interfaces. *)

(** {1 Interfaces} *)

(** Type of parsed interfaces. *)
type t

val single_value_name : string
(** [single_value_name] is the name of the variable used for single value
    interfaces (e.g. by [Check]). *)

val read : Build_file.t -> t
(** [read mli_file] reads and parses the interface from [mli_file]. *)

val tactic_type : t -> string option
(** [tactic_type intf] returns [Some typ] if [intf] is [val __x : typ tactic],
    [None] otherwise. *)

val pp : t -> Pp.t
(** [pp intf] pretty-prints the interface. *)
