Require Import MLtac.MLtac.

MLtac Run ocaml:{{
    open Names
    let subst_vars env sigma ids t =
        let (sigma, subst_list) = 
            List.fold_left (fun (sigma, acc) id ->
                (* Get the type of the variable from the environment *)
                let ty = Environ.named_type id env in
                let ty = EConstr.of_constr ty in
                (* Create a fresh evar of that type *)
                let (sigma, evar) = Evarutil.new_evar env sigma ty ~src:(None, Evar_kinds.MatchingVar (Evar_kinds.FirstOrderPatVar id)) ~naming:(IntroIdentifier id) in
                (* Store the mapping (id -> evar) *)
                (sigma, (id, evar) :: acc)
            ) (sigma, []) (List.of_seq @@ Id.Set.to_seq ids)
        in

        let rec subst sigma t =
            match EConstr.kind sigma t with
            | Var id -> (try CList.assoc id subst_list with Not_found -> t)
            | _ -> EConstr.map sigma (subst sigma) t
        in

        (* Return the new sigma and the modified term *)
        (sigma, subst sigma t)

    let get_pattern env sigma t =
        let ids = Termops.collect_vars sigma t in
        let (sigma, t) = subst_vars env sigma ids t in
        (sigma, Patternops.pattern_of_constr env sigma t)

    let apply_search =
        let open Proofview in
        let open Pp in
        Goal.enter_one begin fun gl ->
            (* Search for lemmas *)
            let conclusion = Goal.concl gl in
            let sigma = Goal.sigma gl in
            let env = Goal.env gl in
            let (sigma, pat) = get_pattern env sigma conclusion in
            let results = ref [] in
            let collect_result ref kind env sigma res = results := ref :: !results in
            Search.search_pattern env sigma pat (SearchOutside []) collect_result;
            if List.is_empty !results
            then CErrors.user_err (str "No theorem could be applied.")
            else
                let pr_globref ref = Libnames.pr_path (Nametab.path_of_global ref) in
                let result_pp = List.fold_left (fun acc res -> acc ++ str "\n" ++ pr_globref res) (str "Here are the list of theorems that could be applied: ") !results in
                let () = Feedback.msg_notice result_pp in
                tclUNIT ()
        end


    let () =
        let open Ltac_plugin in
        let open Tacexpr in
        let mltac _ _ = apply_search in
        let name = { mltac_plugin = "mltac.plugin.runtime"; mltac_tactic = "apply_search"; } in
        let () = Tacenv.register_ml_tactic name [|mltac|] in
  let tac = CAst.make (TacML ({ mltac_name = name; mltac_index = 0 }, [])) in
  let obj () =
    Tacenv.register_ltac true false (Id.of_string "apply_search") tac in
  Mltop.(declare_cache_obj_full (interp_only_obj obj) "mltac.plugin.runtime")
}}.

(* TODO: This is a work-around, I've yet to find a way to register tactics
         that does not rely on plugins.  Surely there must be some way to emulate Ltac definitions? *)
Declare ML Module "mltac.plugin.runtime".

Goal forall a b, andb a b = andb b a.
Proof.
  From Stdlib Require All.
  apply_search.
  intros.
  destruct a, b; reflexivity.
Qed.
