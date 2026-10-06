`Camltac Module`
================

.. cmd:: {? @attributes } Camltac Module @ocaml-module := @ocaml .
   :name: Camltac Module

   .. prodn::
      ocaml-module ::= @ident

   Registers a new module named :token:`ocaml-module` to subsequent snippets. The module's top-level `let`-bindings are evaluated and initialized, as in :cmd:`Camltac Run`.

   .. attr:: @attributes
      :name: attributes

      Locality attributes and build directives.

   .. attr:: @ocaml-module
      :name: ocaml-module

      The name of the module. It must be a valid OCaml module name, i.e., a capitalized identifier.
