Quotations
==========

.. coq:: none

   Require Import Camltac.Camltac.

Camltac provides quotations of the form `{%name| … |}` to input Rocq terms in OCaml. For example, to obtain a well-typed term, one can use the `%constr` quotation:

.. coq::

   Camltac Eval ocaml:({%constr| forall x : nat, x = x |}). (* .unfold *)

`%constr` is the equivalent of Ltac2's `constr:` quotation, with similar semantics.

Other quotations include `%open_constr` for well-typed terms with holes, `%preterm` for untyped terms, `%expr` for concrete syntax, and `%ident` for identifiers.
