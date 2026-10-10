Require Import Camltac.Camltac.

Module M.
  #[export]
  Camltac Module E := ocaml:{{
    let () = Feedback.msg_info (Pp.str "Foo")
  }}.
End M.

Succeed Import M.
