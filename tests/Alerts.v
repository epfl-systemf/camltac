Require Import Camltac.Camltac.

Camltac Run ocaml:(let _ = stdin in ()).
Camltac Run ocaml:(try read_int () with End_of_file -> 0).
