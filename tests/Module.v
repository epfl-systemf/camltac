From Camltac Require Import Camltac.

Camltac Module Test_module := ocaml:(let one = 1).

Camltac Run ocaml:{{ Feedback.msg_info (Pp.int (Test_module.one + Test_module.one)) }}.
