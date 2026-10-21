(** Preprocessing of snippets.

    This file takes care of determining whether preprocessing is applicable, and
    if so, building/caching the appropriate preprocessor driver and creating the
    correct compiler options. *)

(** {1 Preprocessing} *)

type t
(** Type of preprocessing to apply to a source file. *)

val prepare : ppxs:string list -> source:string -> (t, int * Diagnostic.t list) result
(** [prepare ~ppxs ~source] determines how [source] should be preprocessed,
    building a custom driver if necessary. *)

(** {1 Compiler options} *)

val pp_flag : t -> string option
(** [pp_flag pp] returns the value of the OCaml compiler's [-pp] argument to use
    for [pp]. *)

val runtime_deps : ppxs:string list -> string list
(** [runtime_deps ~ppxs] returns the list of runtime dependencies of the given
    preprocessors. *)
