`Camltac Load`
==============

.. cmd:: {? @attributes } Camltac Load @ocaml-file .
   :name: Camltac Load

   .. prodn::
      ocaml-file ::= @string

   Loads the given OCaml file. :token:`ocaml-file` is either a path relative to the current file, or an absolute path.
   The loaded module is named according to :token:`ocaml-file` and made available similarly to :cmd:`Camltac Module`.
