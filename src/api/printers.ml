(** General purpose printers. *)

(** These printers are used by [ppx_deriving.show] in [Camltac Eval]. *)

let top_print fmt f =
  let std_ft = !Topfmt.std_ft in
  Topfmt.std_ft := fmt;
  Fun.protect
    f
    ~finally:(fun () -> Topfmt.std_ft := std_ft)

let pp_expr fmt c =
  top_print fmt (fun () -> Top_printers.ppconstr_expr c)

let pp_glob_constr fmt c =
  top_print fmt (fun () -> Top_printers.ppglob_constr c)

let pp_preterm = pp_glob_constr

let pp_constr fmt c =
  top_print fmt (fun () -> Top_printers.ppconstr c)

let pp_open_constr = pp_constr
