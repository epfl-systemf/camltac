Require Import Camltac.Camltac.

Camltac Module M := ocaml:(let x = 1).
Camltac Module M := ocaml:(let x = 2).
Camltac Eval ocaml:(return M.x).
