Matching goals with variables
=============================

Our first version works great when the conclusion matches exactly the shape of a lemma, but it doesn't generalize well in the presence of variables. For example, if we introduced variables before running `ApplySearch.run ()`, we would not find anything, despite the lemma still applying:

.. coq:: none

   Require Import Camltac.Camltac.

   Module Previous.
     #[local]
     Camltac Module ApplySearch := ocaml:{{
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
           let pattern = Patternops.pattern_of_constr env sigma conclusion in
           print_results (search env sigma pattern);
           return ()
     }}.

.. coq::

   From Stdlib Require List.
   Open Scope list_scope.

   Goal forall A (x y z : list A),
     x ++ y = x ++ z -> y = z.
   Proof.
     intros A x y z. (* ← We added this line. *)

     (* Now our tactic fails: *)
     Camltac Eval ocaml:(ApplySearch.run ()). (* .unfold *)

     (* Stuck. :( *)
   Abort.

To fix this issue, we'll replace our variables with *existential variables* (*evars* in short), which are converted to pattern variables by :rocq-api:`Patternops.pattern_of_constr`.

.. coq:: none

   End Previous.

Turning variables into evars
----------------------------

We introduce a new function, `create_pattern`, that creates the pattern by replacing every variable with a fresh evar:

.. code-block:: coq
   :caption: Tutorial.v
   :linenos:
   :lineno-start: 19
   :emphasize-lines: 7

   (* … *)
   let run () =
     match%rocq goal with
     | _, {| ?conclusion |} ->
       let* env = Tactic.env in
       let* sigma = Tactic.sigma in
       let pattern = create_pattern env sigma conclusion in
       print_results (search env sigma pattern);
       return ()

The `create_pattern` method looks as follows:

.. code-block:: coq
   :caption: Tutorial.v
   :linenos:
   :lineno-start: 4

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

   (* … *)

We use several low-level functions from Rocq APIs:

* :rocq-api:`Evarutil.new_evar` creates a new evar in the evar map, returning the updated evar map and the fresh evar;
* :rocq-api:`Termops.collect_vars` returns the set of named variables in the term;
* :rocq-api:`EConstr.Vars.replace_vars` replaces every variable in `mappings` with its second element.

.. coq:: none

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

Our file now looks as follows:

.. code-block:: coq
   :caption: Tutorial.v
   :linenos:

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

If we rerun the tactic, we now obtain the correct results:

.. coq::

   From Stdlib Require List.
   Open Scope list_scope.

   Goal forall A (x y z : list A),
     x ++ y = x ++ z -> y = z.
   Proof.
     intros A x y z.
     Camltac Eval ocaml:(ApplySearch.run ()). (* .unfold *)

.. coq:: none

   Abort.
