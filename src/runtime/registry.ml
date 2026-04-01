(** Output registry for dynamically loaded code. *)

let outputs : Obj.t list ref = ref []

let register_output t =
  outputs := Obj.repr t :: !outputs

let get_last_output () =
  match !outputs with
  | t :: ts ->
     outputs := ts;
     Obj.obj t
  | [] -> raise Not_found

module StringMap = Map.Make(String)

let registry = ref StringMap.empty

let register name v =
  registry := StringMap.add name (Obj.repr v) !registry

let find name =
  Obj.obj (StringMap.find name !registry)

let register_ltac name tac =
  let open Ltac_plugin in
  let open Tacexpr in
  let mltac _ _ = tac in
  let full_name = { mltac_plugin = "mltac.plugin.runtime"; mltac_tactic = name; } in
  let () = Tacenv.register_ml_tactic full_name [|mltac|] in
  let tac = CAst.make (TacML ({ mltac_name = full_name; mltac_index = 0 }, [])) in
  let obj () =
    Tacenv.register_ltac true false (Names.Id.of_string name) tac in
  Mltop.(declare_cache_obj_full (interp_only_obj obj) "mltac.plugin.runtime")

(* TODO: Remove duplication between [spec] and [typ].
   [spec] is an abstract type that cannot be pattern-matched. *)
let register_ltac2 name spec f =
  let open Ltac2_plugin in
  let full_name = Tac2expr.{ mltac_plugin = "mltac.plugin.runtime"; mltac_tactic = name } in
  Tac2externals.define full_name spec f

let add_resolve_to_db lem db =
  Proofview.Goal.enter begin fun gl ->
    let sigma = Proofview.Goal.sigma gl in
    (* Tolerate applications to please tclABSTRACT in a section *)
    let lem, _ = EConstr.decompose_app sigma lem in
    match EConstr.destRef sigma lem with
    | lem, _ ->
       let () = Hints.add_hints ~locality:Hints.Local db (Hints.HintsResolveEntry [({ Typeclasses.hint_priority = Some 1 ; Typeclasses.hint_pattern = None }, true, lem)]) in
       Tacticals.tclIDTAC
    | exception Constr.DestKO -> Tacticals.tclFAIL (Pp.str "Cannot add non-global to hint database")


    end

let with_hint_db dbs tacK =
  (* [dbs] : list of hint databases *)
  (* [tacK] : tactic to run on a hint *)
  Proofview.Goal.enter begin
      fun gl ->
      let syms = ref [] in
      let _ =
	List.iter (fun l ->
	    (* Fetch the searchtable from the database*)
	    let db = Hints.searchtable_map l in
	    (* iterate over the hint database, pulling the hint *)
	    (* list out for each. *)
	    Hints.Hint_db.iter (fun _ _ hintlist ->
		syms := hintlist::!syms) db) dbs in
      (* Now iterate over the list of list of hints, *)
      List.fold_left
	(fun tac hints ->
	  List.fold_left
	    (fun tac hint1 ->
	      Hints.FullHint.run hint1
		(fun hint2 ->
		  (* match the type of the hint to pull out the lemma *)
		  match hint2 with
		    Hints.Give_exact h
		  | Hints.Res_pf h
		    | Hints.ERes_pf h ->
                     let _, lem = Hints.hint_as_term h in
		     Tacticals.tclORELSE (tacK lem) tac
		  | _ -> tac))
	    tac hints)
	(Tacticals.tclFAIL (Pp.str "No applicable tactic!")) !syms
    end


let () =
  let open Ltac2_plugin in
  let open Tac2ffi in
  let open Tac2externals in
  register_ltac2 "" (list string @-> fun1 constr unit @-> tac unit) with_hint_db
