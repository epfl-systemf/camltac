(** Prelude implicitly open in Camltac snippets. *)

(** This file regroups various definitions, types and modules that are
    made available in Camltac snippets. These include:

    - Syntax for describing tactics: [let*], [return], tacticals such
      as [>>] and [repeat], etc.
    - Standard tactics from Ltac2 ([Ltac2.Std]).
    - Ltac2 APIs.
 *)

include Tactics
include Ltac2.Std
