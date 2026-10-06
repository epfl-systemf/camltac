Camltac's execution model
=========================

Camltac has a particular execution model, since it embeds a full programming language (OCaml) inside Rocq. Hence, several steps are required before OCaml code can be run.

We can broadly distinguish between actions taken during the *syntactic interpretation* (or `synterp`_) phase, and actions during the *interpretation* (`interp`_) phase.

.. _synterp: https://rocq-prover.org/doc/master/refman/language/extensions/compil-steps.html#synterp
.. _interp: https://rocq-prover.org/doc/master/refman/language/extensions/compil-steps.html#interp

Syntactic interpretation
------------------------

During this phase, Camltac parses and compiles snippets, and internally keeps track of compiled modules to be able to reference them in later compilations.

.. toctree::
   :maxdepth: 1

   parsing
   build-directives
   compilation

Interpretation
--------------

The interpretation phase takes care of loading compiled OCaml code in the Rocq process, through :ref:`dynamic linking <dynamic-linking>` and the :ref:`runtime <runtime>`.

.. toctree::
   :maxdepth: 1

   dynamic-linking
   runtime
