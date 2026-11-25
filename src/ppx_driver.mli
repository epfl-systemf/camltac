(** Preprocessor drivers.

    The driver is the executable file that runs the source-to-source (or
    AST-to-AST) transformation. *)

open Filesystem

(** {1 Preprocessor drivers} *)

type t
(** Type of preprocessor drivers. *)

val empty : t
(** [empty] is the driver that does not perform preprocessing. *)

val ppx_rocq : t
(** [ppx_rocq] is the [ppx_rocq] driver. *)

val resolve : t -> Path.t option
(** [resolve driver] returns the absolute path of the driver. *)

(** {1 Custom drivers}

    When more than one preprocessor is involved, we combine them in a
    single executable called a {e custom driver}, so that the AST is
    traversed only once. The cost of compiling this driver is amortized
    over the number of snippets that use the same preprocessors.

    This follows what Dune calls the "fast pipeline" mode:
    {:https://dune.readthedocs.io/en/stable/explanation/preprocessing.html}.
 *)

val build_custom : workspace:Workspace.t -> file:string -> ppxs:string list -> (t, int) result
(** [build_custom ~workspace ~file ~ppxs] combines [ppxs] with
    [ppx_rocq] in a single custom driver that is written in
    [workspace]. *)
