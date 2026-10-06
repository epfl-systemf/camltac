.. _dynamic-linking:

Dynamic linking
===============

Dynamic linking is the process of dynamically extending an OCaml program (here, Rocq) at runtime. In OCaml, dynamic linking is provided by the `Dynlink`_ module. Camltac uses it to load the `.cmxs` or `.cma` files produced by :doc:`compilation` into the running Rocq process, during the interpretation phase.

Loading a snippet
-----------------

Loading a compiled file consists in the following steps:

#. The packages the snippet depends on (e.g. those obtained from build directives) are loaded first, using `Fl_dynload`.
#. The file is loaded with `Dynlink.loadfile` or `Dynlink.loadfile_private`.
#. The file is recorded as loaded, since a dynamically loaded unit can never be unloaded. Camltac uses this to avoid loading the same file twice and to avoid name clashes.

Loading a file runs its module initializers, which is how the snippet's code is executed. Since a snippet cannot be referenced directly from Camltac, results are handed back through the :ref:`runtime <runtime>`.

Public and private loading
--------------------------

Dynlink offers two ways to load a file, which Camltac uses depending on the command:

* Public loading (`loadfile`) makes the compilation units of the file available to files loaded afterwards. This is how Camltac modules are referenceable by later snippets.
* Private loading (`loadfile_private`) keeps the units hidden. It is used for anonymous snippets: :cmd:`Camltac Eval`, :cmd:`Camltac Run`, and snippets embedded in terms, Ltac, and Ltac2. This means such snippets can be loaded without clashing with each other.

.. _Dynlink: https://ocaml.org/manual/5.5/api/Dynlink.html
