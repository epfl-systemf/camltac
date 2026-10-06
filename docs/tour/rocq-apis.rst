Using internal Rocq APIs
========================

.. coq:: none

   Require Import Camltac.Camltac.

Camltac provides full access to Rocq's internal APIs, since the OCaml code runs in the Rocq process. This allows us to access Rocq's latest features, query Rocq for detailed information, or implement features traditionally reserved to OCaml plugins.

For example, here's an implementation of a simple mutable counter that follows backtracks using Rocq's `Summary`_ module:

.. coq::

   Camltac Module Counter := ocaml:{{
     let value =
       Summary.ref ~stage:Interp ~name:"counter" 0

     let inc () =
       value := !value + 1
     let print () =
       Feedback.msg_info (Pp.int !value)
   }}.

Try it out for yourself: run over these snippets, and backtrack to see the effect!

.. coq::

   Module M.
     Camltac Run ocaml:(Counter.print ()). (* .unfold *)
     Camltac Run ocaml:(Counter.inc ()).
     Camltac Run ocaml:(Counter.print ()). (* .unfold *)
   End M.

   (* At the end of the module, the counter is backtracked: *)
   Camltac Run ocaml:(Counter.print ()). (* .unfold *)

   (* …and replayed upon import: *)
   Camltac Run ocaml:(Counter.inc ()).
   Import M. (* .unfold *)

.. _Summary: https://rocq-prover.org/doc/master/api/rocq-runtime/Summary/index.html
