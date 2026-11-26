(** OCaml code snippets. *)

open Filesystem

(** {1 Snippets}

    A snippet is a piece of OCaml code which Camltac compiles and runs.
    Snippets can be written directly in a Rocq file as an [ocaml:(…)]
    quotation, or in a separate [.ml] file loaded with [Camltac Load].

    Every snippet carries its own location. This is crucial for error
    reporting, since this location lets us map compiler diagnostics
    (errors, warnings, alerts) to their original position in the user's
    code. *)

type t
(** Type of OCaml snippets. *)

val make : loc:Loc.t -> file:Path.t -> string -> t
(** [make ~loc ~file contents] creates a snippet from the source
    [contents] located at [loc] in the user project.

    [file] is the path to the file where the snippet appears. *)

val of_file : file:Path.t -> string -> t
(** [of_file ~file contents] creates a snippet from the source
    [contents] present in [file]. This is used by [Camltac Load]. *)

val contents : t -> string
(** [contents snippet] returns the source contents of the snippet. *)

val loc : t -> Loc.t
(** [loc snippet] returns the location of the snippet in the user
    project. *)

val file : t -> Path.t
(** [file snippet] returns the path to the file where the snippet
    appears. *)
