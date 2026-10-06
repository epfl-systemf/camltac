`Camltac Eval`
==============

.. cmd:: Camltac Eval @ocaml .
   :name: Camltac Eval

   Evaluates the given OCaml tactic, of type `a tactic` for some `a`, in the current proof if there is one open, or in a fresh goal. The resulting value is printed.

   Just like :cmd:`Ltac2 Eval`, :cmd:`Camltac Eval` does not modify the current proof state, i.e., its effects are discarded.
