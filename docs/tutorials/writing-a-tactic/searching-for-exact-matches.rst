Searching for exact matches
===========================

In this step, we're going to build a first version of the tactic that uses the `Search` machinery to look for lemmas that `apply` could use. This first version will be restricted to only showing theorems that match our conclusion exactly.

Getting the conclusion
----------------------

The first step is to obtain the conclusion of the current goal. There are several ways to do this, but the simplest one is to use the pattern-matching syntax `match%rocq goal with`:

.. code-block:: coq
   :caption: Tutorial.v
   :linenos:
   :lineno-start: 3
   :emphasize-lines: 3-5

   Camltac Module ApplySearch := ocaml:{{
     let run () =
       match%rocq goal with
       | _, {| ?conclusion |} ->
         search conclusion
   }}.

Here, the wildcard `_` means that hypotheses are not matched on.

Creating a search pattern
-------------------------

Our conclusion is a :ltac2-type:`constr`, but the search command expects a :ltac2-type:`pattern` instead. So, we'll convert our term to a pattern using :rocq-api:`Patternops.pattern_of_constr`:

.. code-block:: coq
   :caption: Tutorial.v
   :linenos:
   :lineno-start: 3
   :emphasize-lines: 5-8

   Camltac Module ApplySearch := ocaml:{{
     let run () =
       match%rocq goal with
       | _, {| ?conclusion |} ->
         let* env = Tactic.env in
         let* sigma = Tactic.sigma in
         let pattern = Patternops.pattern_of_constr env sigma conclusion in
         search env sigma pattern
   }}.

Notice how we're now taking two additional arguments:

- `env` is the environment, of type :rocq-type:`Environ.env`, that map identifiers and variables to their declaration.
- `sigma`, of type :rocq-type:`Evd.evar_map`, is the *evar map* that map *existential variables* to their definition.

Searching for applicable lemmas
-------------------------------

Now, we perform the search using Rocq APIs by calling the :rocq-api:`Search.search_pattern` function:

.. code-block:: coq
   :caption: Tutorial.v
   :linenos:
   :lineno-start: 3
   :emphasize-lines: 2-6

   Camltac Module ApplySearch := ocaml:{{
     let search env sigma pattern =
       let results = ref [] in
       let collect_result res _ _ _ _ = results := res :: !results in
       Search.search_pattern env sigma pattern (SearchOutside []) collect_result;
       !results

     (* … *)
   }}.

We also need to be able to print our results:

.. code-block:: coq
   :caption: Tutorial.v
   :linenos:
   :lineno-start: 10
   :emphasize-lines: 3-11

     (* … *)

     let print_results = function
       | [] -> Feedback.msg_info (Pp.str "No theorem could be applied.")
       | results ->
          let open Pp in
          let pr_ref ref = Libnames.pr_path (Ltac2.Env.path ref) in
          let pp = List.fold_left
            (fun acc res -> acc ++ fnl () ++ pr_ref res)
            (str "Try this: ") results in
          Feedback.msg_info pp

     (* … *)

Notice how we used the :ltac2-val:`Ltac2.Env.path` function from Ltac2; in Camltac, you can freely mix Ltac2 functions with Rocq ones.

Putting everything together
---------------------------

Your `Tutorial.v` file should look like the following:

.. code-block:: coq
   :caption: Tutorial.v
   :linenos:

   Require Import Camltac.Camltac.

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

.. coq:: none

   Require Import Camltac.Camltac.

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

By this point, you should be able to step over the module definition without any error.

To check what we wrote, we can test this version in a small proof script:

.. coq::

   From Stdlib Require List.
   Open Scope list_scope.

   Goal forall A (x y z : list A),
     x ++ y = x ++ z -> y = z.
   Proof.
     Camltac Eval ocaml:(ApplySearch.run ()). (* .unfold *)
     apply List.app_inv_head.
   Qed.
