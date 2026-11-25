(** Error reporting. *)

open Camltac_workspace
open Camltac_toolchain

(** {1 Error reporting} *)

val report : source:Snippet.t -> Diagnostic.t -> unit
(** [report ~source diagnostic] reports the OCaml [diagnostic] for
    [source] to the Rocq process, using {!Feedback} messages for
    warnings and alerts, and {!CErrors} for errors. *)

val report_all : source:Snippet.t -> Diagnostic.t list -> unit
(** [report_all ~source diagnostics] reports the list of [diagnostics]
    on [source] that come from a single compilation.

    If there are multiple errors, only the first one raises. *)
