.. _tutorial-setup:

Setting up a Camltac project
============================

Installing Camltac
------------------

First, you'll need to have opam, Dune and Camltac installed. The installation procedure is described in :ref:`installation`.

Let's make sure that your installation is working:

.. code:: bash

   opam --version
   dune --version
   opam list | grep rocq-camltac # should show rocq-camltac

Then, create an empty directory named `camltac-tutorial`. We'll only create files in this directory.

Creating the project skeleton
-----------------------------

Create the following files in `camltac-tutorial` (you can copy these snippets using the small "Copy" icon):

.. code-block:: lisp
   :caption: dune-project

   (lang dune 3.23)
   (using rocq 0.12)

   (package
    (name camltac-tutorial))

.. code-block:: lisp
   :caption: dune

   (rocq.theory
    (name tutorial)
    (package camltac-tutorial)
    (theories Camltac Ltac2 Stdlib))

.. code-block:: coq
   :caption: Tutorial.v

   Require Import Camltac.Camltac.

   Camltac Run ocaml:{{
     Feedback.msg_info (Pp.str "Hello world!")
   }}.

The `Tutorial.v` file will hold all of our code. For now, there's only a single print, but we're going to modify it and add our tactic there.

If you run `dune build`, you should see `Hello world!` printed on your screen. You can test what you wrote either through `dune build`, or interactively in your editor.

Notice that a `.camltac` directory appeared next to `Tutorial.v` (in `_build/default` if using Dune). This is where Camltac stores its build artifacts. If something goes wrong, you can always remove this directory, since Camltac will regenerate it.

We'll start building the tactic in the next page.

   



