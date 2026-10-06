.. _quotations:

Quotations
==========

.. prodn::
   quotation ::= %{%%@quotation-kind| @quotation-body |%}
   quotation-kind ::= {| constr | open_constr | preterm | expr | ident | qualid | vernac }
   quotation-body ::= {* {| @quotation-text | @antiquotation } }
   constr-quotation ::= %{%%constr| @quotation-body |%}

A quotation of the form `{%kind| … |}` builds a Rocq term or object in OCaml, using Rocq syntax.

Term quotations
---------------

.. attr:: {%%expr| @quotation-body |%}
   :name: expr

   Returns the concrete syntax tree (CST) of the quoted term from the parser.

.. attr:: {%%preterm| @quotation-body |%}
   :name: preterm

   Builds an untyped :ltac2-type:`preterm` from the parsed `expr`. Unlike `expr`, `preterm` have resolved notations, names are qualified, and implicit arguments are made explicit.

.. attr:: {%%constr| @quotation-body |%}
   :name: constr

   Elaborates the term to a :ltac2-type:`constr` by running type-inference on the obtained :ltac2-type:`preterm`.

.. attr:: {%%open_constr| @quotation-body |%}
   :name: open_constr

   Behaves like `{%constr| … |}`, except that existential variables (holes) are allowed in the term.

   For example, `{%open_constr| 1 + _ |}` is accepted, while `{%constr| 1 + _ |}` is rejected.

Other quotations
----------------

.. attr:: {%%ident| @quotation-body |%}
   :name: ident

   Builds a Rocq identifier, following Rocq's identifier parsing rules.

.. attr:: {%%qualid| @quotation-body |%}
   :name: qualid

   Builds a qualified Rocq identifier, i.e., a list of identifiers separated by dots.

.. _antiquotations:

Antiquotations
--------------

.. prodn::
   antiquotation ::= %%%{ @ocaml-expr %}
   | %%@antiquotation-kind:%{ @ocaml-expr %}
   antiquotation-kind ::= {| constr | open_constr | preterm | expr }

An antiquotation `%{x}` splices the term `x` in a quotation. It behaves similarly to `$x` in Ltac2, but unlike Ltac2, `x` does not have to be a variable (it can be any valid OCaml expression).

If the kind is not explicitly specified as in e.g. `%preterm:{x}`, it defaults to the enclosing quotation kind. Hence, `x` in the `%{x}` antiquotation is interpreted as a :ltac2-type:`constr` in `{%constr| … |}`, a :ltac2-type:`preterm` in `{%preterm| … |}`, and so on.
