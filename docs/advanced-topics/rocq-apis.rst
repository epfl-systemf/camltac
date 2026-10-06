Using Rocq's internal APIs
==========================

.. coq:: none

   Require Import Camltac.Camltac.

.. warning::

   Using Rocq internal APIs requires a deep knowledge about how Rocq works, and is unstable. Expect sudden breaking changes across Rocq versions.

Camltac snippets are linked against `rocq-runtime` packages, which means that you can use Rocq internal APIs to query or modify Rocq. Below are a few examples.

Backtrackable state
-------------------

The `Summary` module (`Summary.ref` in particular) provides references which are updated when backtracking. For example, this allows us to implement a backtrackable counter:

.. coq::

   #[local]
   Camltac Module Counter := ocaml:{{
     let counter = Summary.ref ~name:"my_counter" 0

     let incr () = counter := !counter + 1
     let print () = Feedback.msg_info (Pp.int !counter)
   }}.

   Module Foo.
     Camltac Run ocaml:(Counter.print ()). (* .unfold *)
     Camltac Run ocaml:(Counter.incr ()).
     Camltac Run ocaml:(Counter.print ()). (* .unfold *)
   End Foo.

   (* At the end of the module, state is backtracked: *)
   Camltac Run ocaml:(Counter.print ()). (* .unfold *)

Querying the name table
-----------------------

The `Nametab` module maps names to global references (constants, inductives, constructors, etc.) and back. For example, we can resolve a qualified identifier as Rocq would, and print the absolute name of the object it refers to, along with the shortest name that is valid in the current scope:

.. coq::

   Camltac Module Names := ocaml:{{
     open Pp
     open Names

     let print qualid =
       match Nametab.locate qualid with
       | exception Not_found ->
         Feedback.msg_info (Libnames.pr_qualid qualid ++ str " is not in scope")
       | gr ->
         let full = Nametab.path_of_global gr in
         let short = Nametab.shortest_qualid_of_global Id.Set.empty gr in
         Feedback.msg_info
           (Libnames.pr_qualid qualid ++ str " is "
             ++ Libnames.pr_path full
             ++ str ", printed as "
             ++ Libnames.pr_qualid short)
   }}.

   Camltac Run ocaml:(Names.print {%qualid| Init.Nat.add |}). (* .unfold *)
   Camltac Run ocaml:(Names.print {%qualid| nope |}). (* .unfold *)
