(** Build directives. *)

(** A build directive describes how a snippet should be compiled. Directives
    may currently specify libraries, preprocessors, or additional compiler flags to use.

    Directives are given to Camltac commands through Rocq attributes:

    {v
    #[libraries(eio, eio_main), ppx=ppx_deriving.show, flags="-w", flags="-27"]
    Camltac Module M := ocaml:(…).
    v}

    Each attribute takes a list of identifiers ([libraries(eio, eio_main)]), a
    qualified name ([ppx=ppx_deriving.show]) or a string ([flags="-w"]),
    and can be repeated. *)

(** {1 Build directives} *)

(** Type of build directives. *)
type t = private
  { libraries        : string list; (** Libraries to link. *)
    ppx              : string list; (** Preprocessors to use. *)
    compiler_options : string list; (** Extra compilation flags. *)
  }

val empty : t
(** [empty] is the empty set of build directives. *)

val eval_directives : t
(** [eval_directives] is the set of build directives used by the [Eval]
    command. *)

(** {1 Attributes} *)

val attribute : t Attributes.attribute
(** [attribute] is the attribute used to parse build directives. *)
