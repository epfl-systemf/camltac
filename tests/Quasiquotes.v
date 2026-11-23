Require Import Camltac.Camltac.

Camltac Eval ocaml:{{
   let a = {%expr| 1 |} in
   let b = {%expr| 2 |} in
   return {%expr| %expr:{a} + %expr:{b} |}
}}.

Camltac Run ocaml:{{
   let open Names in
   let sub = "012" in
   let c = {%ident| ident_%{sub} |} in
   Feedback.msg_info (Id.print c)
}}.
