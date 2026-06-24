From Camltac Require Import Camltac.

Camltac Module Test_module := ocaml:(let one = 1).

Camltac Run ocaml:{{ let () = Feedback.msg_notice (Pp.int (Test_module.one + Test_module.one)) }}.
