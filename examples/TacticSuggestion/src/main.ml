open Ltac2_plugin
(* the Ltac2 plugin is "packaged" ie its modules are all contained in module Ltac2_plugin
   without this open we would have to refer to eg Ltac2_plugin.Tac2externals below *)

open Tac2externals
(* APIs to register new externals, including the convenience "@->" infix operator *)

open Tac2ffi
(* Translation operators between Ltac2 values and OCaml values in various types *)

open Names

(* Used to distinguish our primitives from some other plugin's primitives.
   By convention matches the plugin's ocamlfind name. *)
let plugin_name = "TacticSuggestion.plugin"

let pname s = { Tac2expr.mltac_plugin = plugin_name; mltac_tactic = s }

(* We define for convenience a wrapper around Tac2externals.define.
   [define "foo"] has type
   [('a, 'b) Ltac2_plugin.Tac2externals.spec -> 'b -> unit].
   Type [('a, 'b) spec] represents a high-level Ltac2 tactic specification. It
   indicates how to turn a value of type ['b] into an Ltac2 tactic.
   The type parameter ['a] gives the type of value produced by interpreting the
   specification. *)
let define s = define (pname s)

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
  let rec get_vars sigma t =
    let open Names in
    match EConstr.kind sigma t with
    | Var id -> Id.Set.singleton id
    | _ -> EConstr.fold sigma (fun ids t -> Id.Set.union ids (get_vars sigma t)) Id.Set.empty t
  in
  let ids = get_vars sigma t in
  let (sigma, t) = subst_vars env sigma ids t in
  (sigma, Patternops.pattern_of_constr env sigma t)

let apply_search () =
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

let () = define "apply_search" (unit @-> tac unit) @@ apply_search
