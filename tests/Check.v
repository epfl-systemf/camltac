From Camltac Require Import Camltac.

(* Check ocaml:(…). *)
Camltac Check ocaml:(1).
Camltac Check ocaml:(let x = () in x).

(* Check module. *)
Camltac Module M1 := ocaml:(let foo () = ()).
Camltac Check M1.

(* Check "file.ml" *)
Camltac Check "test.ml".
