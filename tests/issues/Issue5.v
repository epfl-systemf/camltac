Require Import Camltac.Camltac.

Fail Camltac Eval ocaml:{{
  let* lhs = [%constr "1 + 1"] in
  let* rhs = [%constr "@eq_refl"] in
  [%constr "%{lhs} = %{rhs}"]
}}.
