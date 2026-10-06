Writing a tactic with Camltac
=============================

In this tutorial, you'll learn how to write a simple Camltac tactic that behaves like Lean's `apply?`_ tactic, suggesting lemmas to apply in the current goal. We'll cover:

- How to setup a Dune project for Camltac;
- How to execute Camltac code;
- How to use pattern-matching, Ltac2 APIs, and Rocq APIs in Camltac;
- How to import your tactic in other files;
- How to export your tactic to Ltac2.

Start the tutorial with the :ref:`setup <tutorial-setup>`.

.. toctree::
   :maxdepth: 1
   :hidden:

   setting-up-a-camltac-project
   searching-for-exact-matches
   matching-goals-with-variables
   importing-the-tactic-in-other-files
   using-the-tactic-from-ltac2
   conclusion

.. _apply?: https://lean-lang.org/doc/reference/latest/Tactic-Proofs/Tactic-Reference/#apply___
