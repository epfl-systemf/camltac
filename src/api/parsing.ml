(** API for parsing terms. *)

let parse entry s = Procq.parse_string entry s

let parse_constrexpr = parse Procq.Constr.term
let parse_ident      = parse Procq.Constr.ident
let parse_qualid     = parse Procq.Prim.qualid
let parse_pattern    = parse Procq.Constr.pattern
let parse_vernac     = parse Pvernac.Vernac_.vernac_control
let parse_ltac       = parse Ltac_plugin.Pltac.tactic
let parse_ltac2      = parse Ltac2_plugin.G_ltac2.ltac2_expr

let glob_constr_of_string s =
  Tactics.with_env begin fun env sigma ->
    Constrintern.intern_constr env sigma (parse_constrexpr s)
  end

let constr_of_string s =
  Tactics.with_env begin fun env sigma ->
    Constrintern.interp_constr env sigma (parse_constrexpr s)
  end

let open_constr_of_string s =
  Tactics.with_env begin fun env sigma ->
    Constrintern.interp_open_constr env sigma (parse_constrexpr s)
  end
