(** Support for OCaml tactics in Ltac. *)

open Ltac_plugin

(** This interface is minimalistic on purpose, as the implementation
    is not exposed to other modules. *)

val from_ocaml : Snippet.t ->
  < constant : 'a
  ; dterm : 'b
  ; level : Genarg.rlevel
  ; name : 'c
  ; occvar : 'd
  ; pattern : 'e
  ; red_pattern : 'f
  ; reference : 'g
  ; tacexpr : 'h
  ; term : 'i >
  Tacexpr.gen_tactic_arg
(** [from_ocaml snippet] embeds the given OCaml snippet (representing a tactic)
    in an Ltac expression. *)
