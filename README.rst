.. raw:: html

   <p align="center">
     <img src="./etc/logo.png" alt="Camltac" />
   </p>
   <p align="center">
     OCaml as a Tactic Language for the <a href="https://rocq-prover.org">Rocq Prover</a></br>
     <strong><a href="https://camltac.github.io/latest/tour">Follow the tour »</a></strong>
   </p>
   <p align="center">
     <a href="https://camltac.github.io/latest/tutorials">Tutorials</a> ·
     <a href="https://camltac.github.io/latest/how-tos">How-to guides</a> ·
     <a href="https://camltac.github.io/latest/">Docs</a> ·
     <a href="https://camltac.github.io/latest/reference">Reference</a>
   </p>

.. role:: raw-html(raw)
   :format: html

Overview
========

Camltac is an **OCaml plugin for Rocq that lets you run OCaml code within Rocq scripts**. Camltac makes it possible to define OCaml meta-programs and tactics, and run them in the current Rocq state without the friction and boilerplate of setting up a plugin.

Camltac is both a tactic and a meta-programming language:

* As a tactic language, Camltac provides constructs inspired by Ltac2, including term quotations (``{%constr| … |}``), pattern matching (``match%rocq``), and antiquotations using `ppx_rocq <https://github.com/epfl-systemf/ppx_rocq>`_. Camltac makes it easy to define new tactics by providing the usual tacticals from Ltac2, and a dedicated :raw-html:`<abbr title="Foreign Function Interface">FFI</abbr>` with `Ltac <src/api/ltac.ml>`_ and `Ltac2 <src/api/ltac2.ml>`_.

* As a meta-programming language, Camltac offers a complete meta-programming experience by allowing access to Rocq's internal APIs and state. To ensure stability, Camltac includes the `Ltac2 APIs <https://github.com/epfl-systemf/mltac2>`_ which provide a simple entry point to meta-programming in OCaml.

Have a look at the `tour of Camltac <https://camltac.github.io/latest/tour>`_ for a walkthrough of Camltac's features, or the `examples <./examples>`_ directory for self-contained examples of using Camltac.

Features
========

.. raw:: html

   <p align="center"><img src="etc/showcase.png" width="75%" alt="Showcase image of Camltac" /></p>

Quotations for building terms:
  ``{%constr| … |}``, ``{%open_constr| … |}``, ``{%preterm| … |}``, etc.

Antiquotations:
  ``{%constr| %{x} + %{y} |}``

Pattern-matching over terms:
  ``match%rocq x with``, ``match%lazy x with``, ``match%multi x with``

Pattern-matching over goals:
  ``match%rocq goal with``, ``match%lazy goal with``, ``match%multi goal with``

Modules:
  ``Camltac Module M := ocaml:{{ … }}.``

Interoperability with Ltac2:
  ``Ltac2.FFI.define "my_tactic" (constr @-> tac constr) (fun t -> …)``

Ltac2 APIs and tacticals:
  See the `Ltac2 APIs reference <https://camltac.github.io/latest/reference/ltac2-apis>`_.

Support for OCaml libraries and preprocessors:
  See `examples/ParallelTactics.v <examples/ParallelTactics.v>`_ and `examples/Tracing.v <examples/Tracing.v>`_.

Access to Rocq state and APIs:
  See `a few examples <https://camltac.github.io/latest/advanced-topics/rocq-apis>`_.

Setup
=====

Camltac is available on `Rocq's opam repository <https://github.com/rocq-prover/opam>`_ and supports Rocq ≥ 9.0 with OCaml ≥ 4.14.

To install from opam (`rocq-released`):
   .. code:: sh

      opam install rocq-camltac

To install from Git:
   .. code:: sh

      git clone https://github.com/epfl-systemf/camltac.git
      cd camltac
      dune build @install -p rocq-camltac

Then, import Camltac in your Rocq files (``Require Import Camltac.Camltac.``) and you're ready to go! 🎉

License
=======

Camltac is free software under the `GNU LGPL 2.1 license <LICENSE>`_.
