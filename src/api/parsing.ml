(** API for parsing terms. *)

open Names

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

(** {1 Parsing with antiquotations} *)

(** Generic production rule for antiquotations. *)
let antiquotation_production context =
  (* In Camlp5:
     [ [ "%{"; x = ident; "}" -> { Id.Map.find x context } ] ] *)
  let open Procq in
  Production.make
    (Rule.next
       (Rule.next
          (Rule.next (Procq.Rule.stop)
             ((Symbol.token (Tok.PKEYWORD ("%{")))))
          ((Symbol.nterm Constr.ident)))
       ((Symbol.token (Tok.PKEYWORD ("}")))))
    (fun _ x _ loc -> Id.Map.find x context)

(** Execute function [f] in synterp phase. This function is a hack that tricks
    Rocq by temporarily setting the [Flags.in_synterp] flag. *)
let with_synterp f =
  let old = !Flags.in_synterp_phase in
  Flags.in_synterp_phase := Some true;
  Fun.protect
    ~finally:(fun () -> Flags.in_synterp_phase := old)
    f

(** Execute function [f] where [entry] allows anti-quotations in the map
    [context]. *)
let with_antiquotations entry context f =
  if Names.Id.Map.is_empty context then f ()
  else with_synterp (fun () ->
    let grammar_state = Procq.freeze () in
    let () =
      Egramml.grammar_extend ~ignore_kw:false
        entry
        (Reuse (Some "0", [antiquotation_production context]))
    in
    Fun.protect
      ~finally:(fun () -> Procq.unfreeze grammar_state)
      f
  )

let quasiparse_constrexpr s context =
  with_antiquotations Procq.Constr.term context
    (fun () -> parse_constrexpr s)

let glob_constr_of_quasistring s context =
  Tactics.with_env begin fun env sigma ->
    let context = Id.Map.map (Constrextern.extern_constr ~flags:(PrintingFlags.current ()) env sigma) context in
    Constrintern.intern_constr env sigma (quasiparse_constrexpr s context)
  end

let constr_of_quasistring s context =
  Tactics.with_env begin fun env sigma ->
    let context = Id.Map.map (Constrextern.extern_constr ~flags:(PrintingFlags.current ()) env sigma) context in
    Constrintern.interp_constr env sigma (quasiparse_constrexpr s context)
  end

let open_constr_of_quasistring s context =
  Tactics.with_env begin fun env sigma ->
    let context = Id.Map.map (Constrextern.extern_constr ~flags:(PrintingFlags.current ()) env sigma) context in
    Constrintern.interp_open_constr env sigma (quasiparse_constrexpr s context)
  end
