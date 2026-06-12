(** Support for OCaml tactics in Ltac2. *)

open Ltac2_plugin

(** This interface is minimalistic on purpose, as the implementation
    is not exposed to other modules. *)

val from_ocaml : Snippet.t -> Tac2expr.raw_tacexpr
(** [from_ocaml snippet] embeds the given OCaml snippet (representing a tactic)
    in an Ltac2 expression of type unit. *)
