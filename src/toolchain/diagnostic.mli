(** Parsing of OCaml compiler diagnostics. *)

(** {1 Diagnostics} *)

(** Type of compiler diagnostics. *)
type t =
  { loc      : location option; (** Location of the diagnostic. *)
    severity : severity;        (** Severity. *)
    message  : Pp.t             (** Formatted message. *)
  }

(** Locations as printed by the OCaml compiler. Lines are 1-based,
    characters are 0-based offsets within their line. *)
and location =
  | File of string
  (** [File "file.ml":] *)

  | Line of { file : string; line : int }
  (** [File "file.ml", line l:] *)

  | Range of
      { file  : string;
        lines : int * int;
        chars : int * int }
  (** [File "file.ml", lines l1-l2, characters c1-c2:] *)

(** Type of diagnostic severity. *)
and severity =
  | Alert of string (** [Alert x] *)
  | Warning of int  (** [Warning n] *)
  | Error           (** [Error:] *)
  | Unknown

val parse : In_channel.t -> t list
(** [parse ic] parses the given input channel into a list of diagnostics. *)
