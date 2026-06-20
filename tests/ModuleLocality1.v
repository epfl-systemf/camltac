Require Import Camltac.Camltac.

(** This module is global: *)
Camltac Module Global_module := ocaml:{{
  let value = 0
}}.

(** This module is local: *)
#[local] Camltac Module Local_module := ocaml:{{
  let value = 0
}}.

(** Have a look at ModuleLocality2.v. *)
