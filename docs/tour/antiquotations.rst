Antiquotations
==============

.. coq:: none

   Require Import Camltac.Camltac.

An antiquotation is a part of a quotation that is computed by an OCaml expression. In Camltac, they are written using the `%{…}` syntax:

.. coq::

   Camltac Eval ocaml:{{
     let* lhs = {%constr| 1 + 1 |} in
     let* rhs = {%constr| 2 |} in
     {%constr| %{lhs} = %{rhs} |}
   }}. (* .unfold *)

Unlike the Ltac2 `$` antiquotations, the antiquoted expression between the curly braces does not have to be a variable, and any well-typed OCaml expression is allowed.
