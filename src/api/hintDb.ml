(** API for manipulating hint databases. *)

open Hints
open Names

(** User-facing view of [Hints.hint_ast]. *)
type 'a hint_kind =
  | Apply of 'a
  | EApply of 'a
  | Exact of 'a
  | Immediate of 'a
  | Unfold of Evaluable.t
  | Extern of Pattern.constr_pattern option * Gentactic.glob_generic_tactic

let of_hint_ast = function
  | Res_pf h -> Apply h
  | ERes_pf h -> EApply h
  | Give_exact h -> Exact h
  | Res_pf_THEN_trivial_fail h -> Immediate h
  | Unfold_nth h -> Unfold h
  | Extern (c, tac) -> Extern (c, tac)

module Hint = struct
  type t = Hints.FullHint.t

  let run hint f =
    let f ast = f (of_hint_ast ast) in
    Hints.FullHint.run hint f

  let pattern hint = Hints.FullHint.pattern hint

  let cost hint = Hints.FullHint.priority hint
  let name hint = Hints.FullHint.name hint
  let database hint = Hints.FullHint.database hint

  let print hint = Tactics.(with_env (fun env sigma -> return (Hints.FullHint.print env sigma hint)))
end

(** Type of named hint databases.
    Unfortunately [Hint_db] does not expose the name of the database, so we have
    to carry it around. *)
type t =
  { name: string;
    db: Hint_db.t }

let get_db name = { name; db = Hints.searchtable_map name }

let create ?(local = false) ?(discriminated = true) name =
  Hints.create_hint_db local name TransparentState.full discriminated;
  get_db name

let transparent_state { db } = Hint_db.transparent_state db

let is_opaque cst db =
  let ts = transparent_state db in
  not (TransparentState.is_transparent_constant ts cst)

let set_transparent_state ts { db; name } =
  let db = Hint_db.set_transparent_state db ts in
  { db; name }

let set_opaque cst ~opaque db =
  let open TransparentState in
  let ts = transparent_state db in
  let ts = {
      ts with tr_cst =
                if opaque then Cpred.remove cst ts.tr_cst
                else Cpred.add cst ts.tr_cst
    }
  in set_transparent_state ts db

let discriminated { db } = Hint_db.use_dn db

let name { name } = name

let locality_or_default locality =
  match locality with
  | Some locality -> locality
  | None ->
     (* Per the documentation: [Local] is default inside sections, [Export] is
        the default outside sections. *)
     if Lib.sections_are_opened () then Local
     else Export

let add_hint ?locality entry dbname =
  let locality = locality_or_default locality in
  Hints.add_hints ~locality [dbname] entry;
  get_db dbname

let hint_resolve ?locality ?cost ?pattern globref { db; name } =
  let info = Typeclasses.{ hint_priority = cost; hint_pattern = pattern } in
  let entry = Hints.HintsResolveEntry [(info, true, globref)] in
  add_hint ?locality entry name

let hint_cut ?locality regex { db; name } =
  let entry = Hints.HintsCutEntry regex in
  add_hint ?locality entry name

let hint_extern ?locality ~cost ?pattern tac { db; name } =
  let info = Typeclasses.{ hint_priority = Some cost; hint_pattern = pattern } in
  let entry = Hints.HintsExternEntry (info, tac) in
  add_hint ?locality entry name

let hint_modes ?locality globref ~modes { db; name } =
  let modes = Hints.parse_modes modes in
  let entry = Hints.HintsModeEntry (globref, modes) in
  add_hint ?locality entry name

let get_modes env globref { db; name } =
  let modes = Hints.Hint_db.find_mode env globref db in
  List.map Array.to_list modes

let hint_unfold ?locality globrefs { db; name } =
  let entry = Hints.HintsUnfoldEntry (List.map Tacred.evaluable_of_global_reference globrefs) in
  add_hint ?locality entry name

let remove_hints ?locality globrefs { db; name } =
  let locality = locality_or_default locality in
  Hints.remove_hints ~locality [name] globrefs;
  get_db name

let all_hints { db } =
  let hints = ref [] in
  Hints.Hint_db.iter (fun _ _ list -> hints := list) db;
  !hints

let print { db } =
  Tactics.(with_env (fun env sigma -> return (Hints.pr_hint_db_env env sigma db)))

let print_applicable () =
  let open Tactics in
  let* goals = Proofview.Goal.goals in
  match goals with
  | [] -> CErrors.user_err (Pp.str "No focused goal")
  | goal :: _ ->
     let* goal in
     return ()

let print_reference glob_ref =
  Tactics.(with_env (fun env sigma -> return (Hints.pr_hint_ref env sigma glob_ref)))

let databases () =
  let database_names = Hints.current_db_names () in
  CString.Set.fold (fun name dbs -> get_db name :: dbs) database_names []

(** Default databases *)

let core () = get_db "core"
let arith () = get_db "arith"
let zarith () = get_db "zarith"
let bool () = get_db "bool"
let datatypes () = get_db "datatypes"
let sets () = get_db "sets"
let typeclass_instances () = get_db "typeclass_instances"
let fset () = get_db "fset"
let ordered_type () = get_db "ordered_type"
