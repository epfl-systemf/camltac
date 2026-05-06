Require Import MLtac.MLtac.

MLtac Run ocaml:{{
   let a = [%expr "1"] in
   let b = [%expr "2"] in
   let c = [%expr "%expr:{a} + %expr:{b}"] in
   let env = Global.env () in
   let sigma = Evd.from_env env in
   let p = Ppconstr.pr_constr_expr ~flags:{parentheses = false} env sigma c in
   Feedback.msg_info p
}}.

MLtac Run ocaml:{{
   let open Names in
   let sub = "012" in
   let c = [%ident "ident_%{sub}"] in
   Feedback.msg_info (Id.print c)
}}.
