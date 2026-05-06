(** Runtime support for term and goal pattern matching. *)

open Api.Tactics

type 'a case = pattern * 'a continuation
and pattern = Constrexpr.constr_expr
and 'a continuation = substitution -> 'a tactic
and substitution = Ltac_pretype.patvar_map

let matching_error = (CErrors.UserError Pp.(str "No matching clauses for match."), Exninfo.null)

let match_term t ~cases =
  with_env begin fun env sigma ->
    let rec test_cases (e, info) = function
      | [] -> Proofview.tclZERO ~info e
      | (pattern, k) :: rest ->
         let _, pattern = Constrintern.interp_constr_pattern env sigma pattern in
         try
           let subst = Constr_matching.matches env sigma pattern t in
           let tac = k subst in
           Proofview.tclOR tac (fun e -> test_cases e rest)
         with Constr_matching.PatternMatchingFailure ->
           test_cases (e, info) rest
    in
    test_cases matching_error cases
  end
