.. _build-directives:

Build directives
================

Build directives describe how a snippet should be compiled: which libraries to link, which preprocessors to run, and which extra flags to pass to the OCaml compiler. They are given to Camltac commands as Rocq attributes:

.. code-block:: coq

   #[libraries(eio, eio_main), ppx(ppx_deriving.show), compiler("-w", "-27")]
   Camltac Module M := ocaml:{{ (* … *) }}.

Each attribute accepts a list (`libraries(a, b)`) or a single value (`ppx=ppx_deriving.show`), and can be repeated, in which case the values are concatenated. The accepted attributes are described in the :ref:`reference <commands>`.

Directives are parsed and validated during the :doc:`synterp phase <index>`, before compilation, and are then combined with the arguments described in :doc:`compilation`.

Libraries
---------

Each package listed in `libraries` is checked against the packages known to `findlib`, and an error is reported if it cannot be found. Packages should be listed as dependencies in your build system.

During compilation, the packages are passed to `ocamlfind` with `-package`, together with Camltac's own packages and the runtime dependencies of preprocessors (see below). The resulting list is stored with the compiled snippet, and :ref:`loaded dynamically <dynamic-linking>` before the snippet itself, so that the snippet's initialization can use them.

Preprocessors
-------------

Preprocessing depends on the `ppx` directive:

* If no `ppx` is given, only `ppx_rocq` applies.
* If one or more `ppx` are given, Camltac builds a *custom driver*: a small executable that combines `ppx_rocq` and the requested preprocessors together. This way, the AST is traversed only once instead of once per preprocessor, similarly to Dune's `fast pipeline`_.

Either way, the preprocessor is given to the compiler through its `-pp` flag. The runtime dependencies of each preprocessor are added to the linked libraries.

.. _fast pipeline: https://dune.readthedocs.io/en/stable/explanation/preprocessing.html
