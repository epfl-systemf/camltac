Require Import Camltac.Camltac.

Camltac Run ocaml:{{
   let a = {%expr| 1 |} in
   let b = {%expr| 2 |} in
   let c = {%expr| %expr:{a} + %expr:{b} |} in
   let* pp = Terms.Expr.print c in
   return (Feedback.msg_info pp)
}}.

Camltac Run ocaml:{{
   let open Names in
   let sub = "012" in
   let c = {%ident| ident_%{sub} |} in
   Feedback.msg_info (Id.print c)
}}.
