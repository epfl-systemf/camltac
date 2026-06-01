From Camltac Require Import Camltac.

Camltac Module M := ocaml:(let one = 1).

Camltac Run ocaml:{{ let () = Feedback.msg_notice (Pp.int (M.one + M.one)) }}.
