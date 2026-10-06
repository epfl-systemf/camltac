.. _compilation:

Compilation
===========

Camltac calls the OCaml compiler (`ocamlc` or `ocamlopt`, depending on your installation of Rocq) with the following arguments:

* Rocq packages and Camltac runtime packages (`rocq-camltac.plugin.runtime`, `rocq-camltac.plugin.api`, `ppx_rocq.runtime`) are linked.
* Several modules, such as `Api` and `Prelude`, are open by default so that snippets have immediate access to tactic primitives and Ltac2 APIs.
* Arguments from :ref:`build directives <build-directives>` are added.
* The compiler is instructed to build a shared library (`-shared` or `-a`).

The output of the compilation pipeline is a `.cmxs` or `.cma` file that can be :ref:`dynamically linked <dynamic-linking>`.
