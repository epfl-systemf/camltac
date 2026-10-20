(** General purpose printers to use with [ppx_deriving.show]. *)

module type Env = sig
  val env : Environ.env
  val sigma : Evd.evar_map
end

module Env_printers(E : Env) = struct

  let print fmt pp =
    let result = Pp.string_of_ppcmds pp in
    Format.fprintf fmt "%s" result

  [%%if rocq >= (9, 2)]
  let pp_expr fmt c =
    print fmt (Ppconstr.pr_constr_expr ~flags:{ parentheses = false } E.env E.sigma c)
  [%%else]
  let pp_expr fmt c =
    print fmt (Ppconstr.pr_constr_expr E.env E.sigma c)
  [%%endif]

  let pp_preterm fmt c =
    print fmt (Printer.pr_glob_constr_env E.env E.sigma c)

  let pp_glob_constr = pp_preterm

  let pp_constr fmt c =
    print fmt (Printer.pr_econstr_env E.env E.sigma c)

end
