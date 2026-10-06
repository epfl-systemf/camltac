Quickstart
==========

This page gives simple examples of using Camltac. You can also follow the :ref:`tour <tour>`, follow our :ref:`tutorials <tutorials>`, or have a look at `examples`_ for more examples of projects using Camltac.

To try these examples, you'll need to have Camltac installed on your machine. See :ref:`installation`.

.. _examples: https://github.com/epfl-systemf/camltac/tree/main/examples

Initializing a project
----------------------

To add Camltac to an existing project, you simply need to declare a dependency on the `Camltac` theory (in your `rocq.theory` stanza, if you're using Dune), and add the following line to your file:

.. coq::

   Require Import Camltac.Camltac.

"Hello, world!"
---------------

In Camltac, the most primitive command is :cmd:`Camltac Run`, which runs OCaml code in the current context:

.. coq::

   Camltac Run ocaml:{{
     Feedback.msg_info (Pp.str "Hello, world!")
   }}. (* .unfold *)

Defining a module
-----------------

Camltac lets you define :cmd:`modules <Camltac Module>` to reuse definitions across OCaml snippets:

.. coq::

   Camltac Module M := ocaml:{{
     let one = 1
   }}.

   Camltac Run ocaml:{{
     Feedback.msg_info (Pp.int (M.one))
   }}.

Modules in Camltac follow `Rocq's locality attributes`_, so the following works as well:

.. coq::

   Module M.
     (* This module is not visible outside of M. *)
     #[local]
     Camltac Module Local := ocaml:{{
       let foo = "foo"
     }}.

     (* This module is: *)
     #[export]
     Camltac Module Export := ocaml:{{
       let bar = Local.foo
     }}.
   End M.

   Import M.

   Camltac Run ocaml:{{ Feedback.msg_info (Pp.str Export.bar) }}. (* .unfold *)

   Fail Camltac Run ocaml:{{ Feedback.msg_info (Pp.str Local.foo) }}. (* .fails .unfold *)


.. _Rocq's locality attributes: https://rocq-prover.org/doc/master/refman/language/core/modules.html#controlling-the-scope-of-commands-with-locality-attributes

Writing a tactic
----------------

A tactic is a value of type `a tactic` for some `a`. To evaluate a tactic, use `Camltac Eval`:

.. coq:: unfold

   Camltac Eval ocaml:(return 0).
   Camltac Eval ocaml:({%constr| forall x : nat, x = x |}).
   Camltac Eval ocaml:(let* x = {%constr| 1 |} in {%constr| %{x} + %{x} |}).
