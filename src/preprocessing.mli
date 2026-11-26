(** Preprocessing of snippets.

    This file takes care of determining whether preprocessing is
    applicable, and if so, building the {!Ppx_driver.t} and creating the
    correct compiler options. *)

(** {1 Preprocessing} *)

val select_driver : workspace:Workspace.t -> file:string -> ppxs:string list -> source:string -> (Ppx_driver.t, int) result
(** [select_driver ~workspace ~file ~ppxs ~source] determines how
    [source] should be preprocessed, building a custom driver if
    necessary. *)

(** {1 Compiler options} *)

val pp_flag : Ppx_driver.t -> string option
(** [pp_flag pp] returns the value of the OCaml compiler's [-pp]
    argument to use for [pp]. *)
