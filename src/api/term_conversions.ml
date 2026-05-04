(** Operations on terms. *)

open Tactics

(** {1 Conversions} *)

module Expr = struct
  type t = Constrexpr.constr_expr

  let of_glob_constr c =
    with_env begin fun env sigma ->
      let flags = (PrintingFlags.current ()).extern in
      let extern_env = Constrextern.extern_env ~flags env sigma in
      return (Constrextern.extern_glob_constr extern_env c)
    end

  let of_constr c =
    with_env begin fun env sigma ->
      let flags = PrintingFlags.current () in
      return (Constrextern.extern_constr ~flags env sigma c)
    end
end

module Glob_constr = struct
  type t = Glob_term.glob_constr

  let of_expr e =
    with_env begin fun env sigma ->
      return (Constrintern.intern_constr env sigma e)
    end

  let of_constr c =
    with_env begin fun env sigma ->
      let flags = (PrintingFlags.current ()).detype in
      return (Detyping.detype Detyping.Now ~flags env sigma c)
    end
end

module Constr = struct
  type t = EConstr.constr

  let of_expr e =
    with_env begin fun env sigma ->
      let constr, ustate = Constrintern.interp_constr env sigma e in
      let sigma = Evd.merge_ustate sigma ustate in
      Proofview.Unsafe.tclEVARS sigma >>
      return constr
    end

  let of_glob_constr c =
    with_env begin fun env sigma ->
      let constr, ustate = Pretyping.understand env sigma c in
      let sigma = Evd.merge_ustate sigma ustate in
      Proofview.Unsafe.tclEVARS sigma >>
      return constr
    end
end

module Open_constr = struct
  type t = EConstr.t

  let of_expr e =
    with_env begin fun env sigma ->
      let sigma, constr = Constrintern.interp_open_constr env sigma e in
      Proofview.Unsafe.tclEVARS sigma >>
      return constr
    end

  let of_glob_constr e =
    with_env begin fun env sigma ->
      let sigma, econstr = Pretyping.understand_tcc env sigma e in
      Proofview.Unsafe.tclEVARS sigma >>
      return econstr
    end
end
