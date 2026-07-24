Require Import Camltac.Camltac.
Require Import Ltac2.Ltac2.

Camltac Run ocaml:{{
  Ltac2.FFI.(define "foo" (unit @-> ret unit) (fun () -> ()))
}}.

Ltac2 @external foo : unit -> unit := "camltac.plugin.runtime" "foo".

(** Should suceed: *)
Succeed Ltac2 Eval (foo ()).
