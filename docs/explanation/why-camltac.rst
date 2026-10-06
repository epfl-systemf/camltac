.. _why-camltac:

Why Camltac?
============

.. coq:: none

   Require Import Camltac.Camltac.

This page explains the problem Camltac tries to solve, and where it sits among the other ways of writing tactics and meta-programs in Rocq. We recommend also having a look at the `Rocqshop 2026 extended abstract`_ for more background information.

.. _Rocqshop 2026 extended abstract: https://coq-workshop.gitlab.io/2026/files/EA6.pdf

Tactic languages in Rocq
------------------------

Tactic languages let users fill the gaps of a proof assistant with automation of their own. In Rocq, several tactic languages co-exist, each with its own strengths and favored use-cases:

* `Ltac` and `Ltac2` are the built-in tactic languages of Rocq, well-suited for lightweight scripting. Ltac, the original tactic language, is untyped and has often surprising semantics. Ltac2 was introduced to fix Ltac's weaknesses by introducing a static type system and a set of APIs to interact with Rocq.
* `Mtac2` defines typed tactics in a monad written in Gallina, ruling out entire classes of bugs at compile-time.
* `MetaRocq` models Rocq's Calculus of Inductive Constructions (CIC) inside Rocq, and provides a way to define meta-programs through the `TemplateMonad`. This approach enables verified meta-programming, restricted to what MetaRocq models.
* `Elpi` embeds a λProlog interpreter with a higher-order representation of terms, which is great for traversing binders and generating code (e.g. in HierarchyBuilder).

OCaml plugins are powerful
~~~~~~~~~~~~~~~~~~~~~~~~~~

As the implementation language of Rocq, OCaml itself can also be used to define meta-programs and tactics, and Rocq supports loading OCaml plugins that use its internals directly. This gives plugins (almost) unlimited power: they can implement new vernacular commands and tactics, memoize results, perform I/O, use OCaml 5 parallelism, run at native speed, and reuse any OCaml library or preprocessor. Many of Rocq's own tactics, such as `congruence`, are implemented this way.

…but inconvenient
~~~~~~~~~~~~~~~~~~

In practice however, OCaml plugins are a last resort reserved to experts, because of three compounding problems:

*Stability*
   Rocq makes no guarantees about the stability of its internal APIs. Plugins break between releases, and keeping up requires a non-trivial maintenance effort.

*Boilerplate*
   A plugin needs a `dune-project`, `dune` files, a grammar file, a loader `.v` file, and a theory declaration. A single "Hello world" tactic can take up to ten files.

*Friction*
   Plugin code is written, compiled and edited separately from the Rocq scripts that use it. It cannot easily access definitions from the current environment, and building terms by hand means manipulating de Bruijn indices, which is tricky to get right.

What Camltac provides
---------------------

Camltac lets you write OCaml inside Rocq files and runs it in the current Rocq state. It provides:

* **Stability:** Camltac ships the :doc:`Ltac2 APIs </reference/ltac2-apis>` as OCaml modules. These APIs are maintained as part of Rocq's CI, so code that uses them is much less likely to break than code using raw internals. You can still reach for the internal APIs when you need them (see :doc:`advanced topics </advanced-topics/rocq-apis>`).
* **Low boilerplate and friction:** Snippets are compiled and loaded on the fly (see :doc:`the execution model <execution-model/index>`), so there is no plugin to set up, and the code lives next to the proofs that use it. You can :ref:`run it, define modules, and call it from Ltac and Ltac2 <tour>` without leaving your editor.
* **Convenience:** The :ref:`quotations <quotations>` of `ppx_rocq` let you write Rocq terms in Rocq syntax inside OCaml, and the :doc:`pattern matching </reference/pattern-matching>` constructs let you destructure terms and goals.

Using OCaml also means that we obtain all of its features "for free": type-checking, pattern-matching exhaustiveness checking, the language server and editor support, the library ecosystem, native compilation, and effects and parallelism in OCaml 5.

How it compares
---------------

Camltac is both a *meta-programming* language, since it gives access to Rocq's APIs, and a *tactic* language, since it comes with quotations, pattern matching, tacticals and an FFI to Ltac and Ltac2. The Rocq framework closest to it in spirit is Elpi, which also embeds a full programming language in Rocq. Outside of Rocq, Isabelle (with Isabelle/ML meta-programming), the LCF-style provers HOL4 and HOL Light, and Lean 4 (written in Lean) offer a similar experience, where meta-programs are written in a programming language next to proofs.

Choosing between Camltac and other tactic languages mostly depends on your use case. Camltac is a good fit when you need the power or performance of OCaml, its libraries, or Rocq's internals, without the burden of a plugin. See also the :doc:`comparison with Ltac2 </reference/ltac2-comparison>`.
