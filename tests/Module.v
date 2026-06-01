From Camltac Require Import Camltac.

Camltac Module M := ocaml:{{
   let my_print s = Feedback.msg_notice (Pp.str s)
}}.

Camltac Run ocaml:{{ let () = M.my_print "Hello from M!\n" }}.
