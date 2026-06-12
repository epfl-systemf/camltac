(** Term API. *)

open Tactics
open Tactics.Syntax

(** {1 Term representations} *)

module Definitions = struct
  type constrexpr = Constrexpr.constr_expr
  type expr = constrexpr
  type glob_constr = Glob_term.glob_constr
  type preterm = glob_constr
  type constr = EConstr.constr
  type open_constr = EConstr.t
end

include Definitions

(** {1 Conversions} *)

module Expr = struct
  type t = constrexpr

  let of_glob_constr c =
    let* env in
    let* sigma in
    let flags = (PrintingFlags.current ()).extern in
    let extern_env = Constrextern.extern_env ~flags env sigma in
    return (Constrextern.extern_glob_constr extern_env c)

  let of_constr c =
    let* env in
    let* sigma in
    let flags = PrintingFlags.current () in
    return (Constrextern.extern_constr ~flags env sigma c)

  let print c =
    let* env in
    let* sigma in
    return (Ppconstr.pr_constr_expr ~flags:{ parentheses = false } env sigma c)
end

module Glob_constr = struct
  type t = glob_constr

  let of_constrexpr e =
    let* env in
    let* sigma in
    return (Constrintern.intern_constr env sigma e)

  let of_constr c =
    let* env in
    let* sigma in
    let flags = (PrintingFlags.current ()).detype in
    return (Detyping.detype Detyping.Now ~flags env sigma c)

  let print c =
    let* env in
    let* sigma in
    return (Printer.pr_glob_constr_env env sigma c)
end

module Constr = struct
  type t = constr

  let of_constrexpr e =
    let* env in
    let* sigma in
    let constr, ustate = Constrintern.interp_constr env sigma e in
    let sigma = Evd.merge_ustate sigma ustate in
    Proofview.Unsafe.tclEVARS sigma >>
    return constr

  let of_glob_constr c =
    let* env in
    let* sigma in
    let constr, ustate = Pretyping.understand env sigma c in
    let sigma = Evd.merge_ustate sigma ustate in
    Proofview.Unsafe.tclEVARS sigma >>
    return constr

  let print c =
    let* env in
    let* sigma in
    return (Printer.pr_econstr_env env sigma c)
end

module Open_constr = struct
  type t = open_constr

  let of_constrexpr e =
    let* env in
    let* sigma in
    let sigma, constr = Constrintern.interp_open_constr env sigma e in
    Proofview.Unsafe.tclEVARS sigma >>
    return constr

  let of_glob_constr e =
    let* env in
    let* sigma in
    let sigma, econstr = Pretyping.understand_tcc env sigma e in
    Proofview.Unsafe.tclEVARS sigma >>
    return econstr

  let print = Constr.print
end
