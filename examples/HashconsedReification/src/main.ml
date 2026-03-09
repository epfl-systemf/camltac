open Ltac2_plugin
(* the Ltac2 plugin is "packaged" ie its modules are all contained in module Ltac2_plugin
   without this open we would have to refer to eg Ltac2_plugin.Tac2externals below *)

open Tac2externals
(* APIs to register new externals, including the convenience "@->" infix operator *)

open Tac2ffi
(* Translation operators between Ltac2 values and OCaml values in various types *)

(* Used to distinguish our primitives from some other plugin's primitives.
   By convention matches the plugin's ocamlfind name. *)
let plugin_name = "HashconsedReification.plugin"

let pname s = { Tac2expr.mltac_plugin = plugin_name; mltac_tactic = s }

(* We define for convenience a wrapper around Tac2externals.define.
   [define "foo"] has type
   [('a, 'b) Ltac2_plugin.Tac2externals.spec -> 'b -> unit].
   Type [('a, 'b) spec] represents a high-level Ltac2 tactic specification. It
   indicates how to turn a value of type ['b] into an Ltac2 tactic.
   The type parameter ['a] gives the type of value produced by interpreting the
   specification. *)
let define s = define (pname s)

let ref_to_constr ref =
  EConstr.of_constr (UnivGen.constr_of_monomorphic_global (Global.env ()) ref)
let constr_of_qualid n =
  let qualid = Libnames.qualid_of_string n in
  lazy (let ref = Nametab.locate qualid in ref_to_constr ref)

let bool_typ = constr_of_qualid "bool"
let trueb    = constr_of_qualid "true"
let falseb   = constr_of_qualid "false"
let andb     = constr_of_qualid "andb"
let orb      = constr_of_qualid "orb"
let negb     = constr_of_qualid "negb"

let bool_expr = constr_of_qualid "bool_expr"
let bool_expr_Literal = constr_of_qualid "Literal"
let bool_expr_Var = constr_of_qualid "Var"
let bool_expr_Neg = constr_of_qualid "Neg"
let bool_expr_And = constr_of_qualid "And"
let bool_expr_Or = constr_of_qualid "Or"

(* Let us define our own data type in OCaml, and convert it from/to constr when necessary. *)

type bool_expr =
  | Literal of bool
  | Neg of bool_expr
  | And of bool_expr * bool_expr
  | Or of bool_expr * bool_expr

type constructors = {
    literal_cons: bool -> bool_expr;
    neg_cons: bool_expr -> bool_expr;
    and_cons: bool_expr -> bool_expr -> bool_expr;
    or_cons: bool_expr -> bool_expr -> bool_expr;
  }

let rec quote factories evd t =
  match EConstr.kind evd t with
  | Construct _ -> factories.literal_cons (EConstr.eq_constr evd t @@ Lazy.force trueb)
  | App (head, args) when head = Lazy.force negb && Array.length args = 1 ->
     let arg = quote factories evd args.(0) in
     factories.neg_cons arg
  | App (head, args) when Array.length args = 2 ->
     let left = quote factories evd args.(0) in
     let right = quote factories evd args.(1) in
     let op =
       if head = Lazy.force andb then factories.and_cons
       else if head = Lazy.force orb then factories.or_cons
       else failwith "Unknown boolean function."
     in op left right
  | Var ident ->
     failwith "Variables aren't supported, because I don't want to convert OCaml strings to Rocq strings by hand :("
  | _ -> CErrors.user_err (Pp.str "Unrecognized term.")

let rec unquote e =
  let make cons args =
    let cons = Lazy.force cons in
    EConstr.mkApp (cons, args)
  in
  match e with
  | Literal true -> make bool_expr_Literal [| Lazy.force trueb |]
  | Literal false -> make bool_expr_Literal [| Lazy.force falseb |]
  | Neg e' -> make bool_expr_Neg [| unquote e' |]
  | And (e1, e2) -> make bool_expr_And [| unquote e1; unquote e2 |]
  | Or (e1, e2) -> make bool_expr_Or [| unquote e1; unquote e2 |]

(* Our reification function is parametrized by how we construct new applied terms.
   For simple reification, taking [factories = default_factories] works.
   If we want hashconsing, we must use a memoizing variant. *)
let reify factories t =
  let env = Global.env () in
  let evd = Evd.from_env env in
  let t = Termops.strip_head_cast evd t in
  unquote (quote factories evd t)

let default_factories = {
    literal_cons = (fun b -> Literal b);
    neg_cons = (fun a -> Neg a);
    and_cons = (fun a b -> And (a, b));
    or_cons = (fun a b -> Or (a, b));
}

let cache: (bool_expr, bool_expr) Hashtbl.t = Hashtbl.create 97
let memoized_factories =
  let get_cached value =
    try Hashtbl.find cache value
    with Not_found -> Hashtbl.add cache value value; value
  in {
    literal_cons = (fun b -> get_cached (Literal b));
    neg_cons = (fun a -> get_cached (Neg a));
    and_cons = (fun a b -> get_cached (And (a, b)));
    or_cons = (fun a b -> get_cached (Or (a, b)));
  }

let () = define "reify" (constr @-> ret constr) @@ (reify default_factories)
let () = define "hashcons_reify" (constr @-> ret constr) @@ (reify memoized_factories)
