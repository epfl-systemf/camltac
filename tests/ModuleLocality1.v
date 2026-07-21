Require Import Camltac.Camltac.

(** This module is available by using Require: *)
#[global]
Camltac Module Global_module := ocaml:{{
  let value = 0
}}.

(** This module is available by using Import: *)
#[export]
Camltac Module Export_module := ocaml:{{
  let value = 0
}}.

(** This module is local and not accessible outside of this file: *)
#[local] Camltac Module Local_module := ocaml:{{
  let value = 0
}}.

(** Have a look at ModuleLocality2.v. *)
