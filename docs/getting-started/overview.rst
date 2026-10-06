Overview
========

Camltac is a tactic and meta-programming language for the `Rocq Prover`_ that lets you write OCaml code within Rocq files. Using Camltac, you can define OCaml tactics and meta-programs, and run them on-the-fly inside your Rocq session.

Writing OCaml code in Camltac comes with all the benefits of OCaml: native performance, a helpful type-system, tooling support, nice ergonomics, and a rich ecosystem of libraries and preprocessors. Moreover, recent versions of OCaml 5 come with support for `parallelism`_ and `algebraic effects`_, which lets you express more meta-programs easily.

In addition to regular OCaml features, Camltac provides a few additional ones for writing tactics:

* You can build Rocq terms in Camltac using :ref:`quotations <quotations>` such as `{%constr| … |}` (equivalent to Ltac2's `constr:(…)`);

* Camltac supports :ref:`antiquotations <antiquotations>` (`%{…}`) inside quotations, :ref:`pattern matching over terms <pattern-matching-over-terms>` (`match%rocq x with`), and :ref:`pattern matching over goals <pattern-matching-over-goals>` (`match%rocq goal with`).

* Camltac ships with the entire `Ltac2 APIs`_, and provides the usual tacticals to compose tactics together.

For the motivation behind Camltac and how it compares to Ltac2, OCaml plugins, and other tactic languages, have a look at :ref:`why-camltac`.

If you'd like to play immediately with Camltac, the next page shows a few small examples to try out. You can head to :ref:`installation` to install Camltac.

.. _Rocq Prover: https://rocq-prover.org
.. _parallelism: https://ocaml.org/manual/5.5/parallelism.html
.. _algebraic effects: https://ocaml.org/manual/5.5/effects.html
.. _Ltac2 APIs: https://github.com/epfl-systemf/mltac2
