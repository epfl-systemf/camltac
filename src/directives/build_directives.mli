(** Definition and parsing of build directives. *)

(** {1 Build directives} *)

(** A build directive is a special annotation recognized by Camltac that describes how
    a file or snippet should be compiled. It can contain libraries to link,
    preprocessors to use, or extra compilation arguments. *)

(** Type of build directives. *)
type t =
  private
    { compiler_options : string list; (** Extra compilation options. *)
      ppx : string list;              (** Preprocessors to apply. *)
      libraries : string list;        (** Libraries to use. *)
    }

val empty : t
(** [empty] returns the empty set of directives. *)

val get : string -> (t, int) result
(** [get file] parses the given OCaml file and returns [Ok directives] upon success,
    or [Error code] otherwise. *)
