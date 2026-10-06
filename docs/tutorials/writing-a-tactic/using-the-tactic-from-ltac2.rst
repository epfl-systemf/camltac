Using the tactic from Ltac2
===========================

So far, we had to use `Camltac Eval` to evaluate our tactic inside a proof. Another alternative would be to declare our tactic as an Ltac2 tactic, so that existing proof scripts could use it more easily.

Registering the tactic to Ltac2
-------------------------------

We can create an Ltac2 tactic from a Camltac tactic by using the `FFI` module:

.. code-block:: coq
   :caption: Tutorial.v
   :linenos:
   :lineno-start: 41

   (* … *)

   Camltac Run ocaml:{{
     Ltac2.FFI.(define "apply_search"
       (unit @-> tac unit)
       ApplySearch.run)
   }}.

The `unit @-> tac unit` specifies the type to the Ltac2 FFI from OCaml.

We must also register our tactic on the Ltac2 side to be able to call it directly by name:

.. code-block:: coq
   :caption: Tutorial.v
   :linenos:
   :lineno-start: 49

   Require Import Ltac2.Ltac2.

   Ltac2 @external apply_search : unit -> unit :=
     "rocq-camltac.plugin.runtime" "apply_search".

.. coq:: none

   Require Import Camltac.Camltac.
   
   Camltac Module ApplySearch := ocaml:{{
     let create_pattern env sigma t =
       let new_evar_for var (sigma, mappings) =
         let typ = EConstr.of_constr (Environ.named_type var env) in
         let sigma, evar = Evarutil.new_evar env sigma typ
           ~src:(None, Evar_kinds.MatchingVar (Evar_kinds.FirstOrderPatVar var))
           ~naming:(IntroIdentifier var)
         in (sigma, (var, evar) :: mappings)
       in
       let vars = Termops.collect_vars sigma t in
       let sigma, mappings = Names.Id.Set.fold new_evar_for vars (sigma, []) in
       Patternops.pattern_of_constr env sigma 
         (EConstr.Vars.replace_vars sigma mappings t)
   
     let search env sigma pattern =
       let results = ref [] in
       let collect_result res _ _ _ _ = results := res :: !results in
       Search.search_pattern env sigma pattern (SearchOutside []) collect_result;
       !results
   
     let print_results = function
       | [] -> Feedback.msg_info (Pp.str "No theorem could be applied.")
       | results ->
          let open Pp in
          let pr_ref ref = Libnames.pr_path (Ltac2.Env.path ref) in
          let pp = List.fold_left
            (fun acc res -> acc ++ fnl () ++ pr_ref res)
            (str "Try this: ") results in
          Feedback.msg_info pp
   
     let run () =
       match%rocq goal with
       | _, {| ?conclusion |} ->
         let* env = Tactic.env in
         let* sigma = Tactic.sigma in
         let pattern = create_pattern env sigma conclusion in
         print_results (search env sigma pattern);
         return ()
   }}.

   Camltac Run ocaml:{{
     Ltac2.FFI.(define "apply_search"
       (unit @-> tac unit)
       ApplySearch.run)
   }}.

   Require Import Ltac2.Ltac2.

   Ltac2 @external apply_search : unit -> unit :=
     "rocq-camltac.plugin.runtime" "apply_search".

   From Stdlib Require List.
   Open Scope list_scope.

Calling the tactic
------------------

We can now directly call the tactic from Ltac2:

.. coq::

   Goal forall A (x y z : list A),
     x ++ y = x ++ z -> y = z.
   Proof.
     intros A x y z.
     apply_search (). (* .unfold *)

.. coq:: none

   Abort.

Using Ltac2 notations, we can even obtain the original `apply?` syntax:

.. coq::

   Ltac2 Notation "apply?" := apply_search ().

   Goal forall A (x y z : list A),
     x ++ y = x ++ z -> y = z.
   Proof.
     intros A x y z.
     apply?. (* .unfold *)

.. coq:: none

   Abort.
