(** General purpose printers to use with [ppx_deriving.show]. *)

let with_global_env fmt f =
  let env = Global.env () in
  let sigma = Evd.from_env env in
  let result = Pp.string_of_ppcmds (f env sigma) in
  Format.fprintf fmt "%s" result

let pp_expr fmt c =
  with_global_env fmt (fun env sigma -> Ppconstr.pr_constr_expr ~flags:{ parentheses = false } env sigma c)

let pp_preterm fmt c =
  with_global_env fmt (fun env sigma -> Printer.pr_glob_constr_env env sigma c)

let pp_glob_constr = pp_preterm

let pp_constr fmt c =
  with_global_env fmt (fun env sigma -> Printer.pr_econstr_env env sigma c)

let pp_open_constr = pp_constr
