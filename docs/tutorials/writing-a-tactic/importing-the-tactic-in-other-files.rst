Importing the tactic in other files
===================================

One important aspect of Camltac is that Camltac modules follow Rocq's locality system, i.e., they can be made `#[local]`, `#[export]`, or `#[global]`.

Create a new file called `Test.v` that simply imports `Tutorial.v`:

.. code-block:: coq
   :caption: Test.v
   :linenos:

   Require Import Tutorial.

By default, Camltac modules are `#[export]`, but we can make this explicit in `Tutorial.v`:

.. code-block:: coq
   :caption: Tutorial.v
   :linenos:
   :lineno-start: 3
   :emphasize-lines: 1

   #[export]
   Camltac Module ApplySearch := ocaml:{{
     (* … *)

In `Test.v`, you can check that `ApplySearch` was imported using `Camltac Check`: 

.. coq:: none

   Require Import Camltac.Camltac.

   Module Tutorial.
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
   End Tutorial.

   Import Tutorial.

.. coq::

   Camltac Check ApplySearch. (* .unfold *)
