.. _installation:

Installation
============

We recommend using `opam <https://opam.ocaml.org/>`__ to install Camltac.

Using opam
----------

Camltac is available on the `rocq-released` opam repository, and requires Rocq ≥ 9.0 with OCaml ≥ 4.14. To install Camltac:

1. Add the `rocq-released` opam repository:

   .. code:: bash

      opam repo add rocq-released https://rocq-prover.github.io/opam/released/

2. Install Camltac:

   .. code:: bash

      opam install rocq-camltac
   
Building from sources
---------------------

You can build Camltac from sources using `Dune <https://github.com/ocaml/dune>`_:

.. code:: bash

   git clone https://github.com/epfl-systemf/camltac.git
   cd camltac
   dune build @install -p rocq-camltac


Testing your setup
------------------

To test that your setup is OK, the following code should evaluate correctly:

.. coq::

   Require Import Camltac.Camltac.

   Camltac Eval ocaml:{{ return (1 + 1) }}. (* .unfold *)
