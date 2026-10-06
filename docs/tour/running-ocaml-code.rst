Running OCaml code
==================

.. coq:: none

   Require Import Camltac.Camltac.

At its core, Camltac provides a way to run OCaml code within Rocq files. Following the tradition in the programming community, let's print "Hello world!":

.. coq::

   Camltac Run ocaml:{{
     Feedback.msg_info (Pp.str "Hello world!")
   }}. (* .unfold *)

Camltac recognizes OCaml syntax embedded between `{{` and `}}`, and interprets it as top-level OCaml expressions (i.e. the same expressions that you would put in an `.ml` file). This means, for example, that you can use `let` bindings:

.. coq::

   Camltac Run ocaml:{{
     let hello = "Hello"
     let world = " wonderful world!"

     let () = Feedback.msg_info (Pp.str (hello ^ world))
   }}. (* .unfold *)

Here, `hello` and `world` cannot be accessed outside of the curly braces. To expose them, you need to define a *module*:

.. coq::

   Camltac Module M := ocaml:{{
     let hello = "Hello"
     let world = " from module M!"
   }}.

   Camltac Run ocaml:{{
     Feedback.msg_info (Pp.str (M.hello ^ M.world))
   }}. (* .unfold *)

Camltac can also load external `.ml` files:

.. coq::

   Camltac Load "file.ml". (* .unfold *)

The `Camltac Load "file.ml"` command behaves equivalently to `Camltac Module File := ocaml:(<contents of file.ml>)`.

.. note::

   There is some setup required for `Camltac Load` to work with Dune, described in the :ref:`dune-setup` guide.
