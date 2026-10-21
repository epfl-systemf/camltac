(** Parsing of OCaml compiler diagnostics. *)

(** {1 Diagnostic} *)

(** Type of diagnostic severity. *)
type severity =
  | Alert of string
  | Warning of int
  | Error
  | Unknown

(** Type of compiler diagnostics. *)
type t =
  { loc      : Loc.t option; (** Location of the diagnostic. *)
    severity : severity;     (** Severity. *)
    message  : Pp.t          (** Formatted message. *)
  }

val parse : source:Snippet.t -> In_channel.t -> t list
(** [parse ~source ic] parses the given input channel into a list
    of diagnostics for the given [source] snippet. *)
