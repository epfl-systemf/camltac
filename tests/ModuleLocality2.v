Require Import Camltac.Camltac.
Require ModuleLocality1.

Camltac Eval ocaml:{{ return Global_module.value }}.
Fail Camltac Eval ocaml:{{ return Local_module.value }}.
