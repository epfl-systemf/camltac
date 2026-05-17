From Camltac Require Import Camltac.

Camltac Run ocaml:(Runtime.Registry.register "one" 1).

Camltac Run ocaml:{{
  let one = Runtime.Registry.find "one" in
  Feedback.msg_notice (Pp.int (one + one))
}}.
