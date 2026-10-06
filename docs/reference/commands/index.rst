.. _commands:

Commands
========

.. coq:: none

   Require Import Camltac.Camltac.

.. toctree::
   :maxdepth: 1

   Run
   Module
   Load
   Eval
   Check

General syntax
--------------

OCaml code
~~~~~~~~~~

.. prodn::
   ocaml ::= ocaml:@open-delim @ocaml-code @close-delim
   open-delim ::= {+ ( }
   | {+ [ }
   | {+ %{ }
   close-delim ::= {+ ) }
   | {+ ] }
   | {+ %} }

The code must be closed by as many closing delimiters as there were opening ones, of the matching kind.
For example, ``ocaml:(code)``, ``ocaml:[[code]]`` and ``ocaml:{{{code}}}`` are all valid.

.. note::

   In general, you should prefer ``ocaml:{{code}}``, since Rocq treats `:{{` as a special case that does not end parsing on `.`.


Attributes
~~~~~~~~~~

.. prodn::
   attributes ::= #[ {+, @attribute } ]
   attribute ::= {| local | global | export }
   | libraries( {+, @package } )
   | ppx( {+, @package } )
   | compiler( {+, @compiler-flag } )

Some commands, such as :cmd:`Camltac Run` or :cmd:`Camltac Module`, accept additional attributes that change their behavior.

Locality
########

The locality attributes (:attribute:`local`, :attribute:`global`, :attribute:`export`) specify how Camltac modules and snippets behave when imported.

.. attr:: local
   :name: local

   The Camltac module is local to the current Rocq module; it disappears when the module is closed.

.. attr:: global
   :name: global

   The Camltac module is loaded when the enclosing Rocq module is :cmd:`Require`-ed.

.. attr:: export
   :name: export

   The Camltac module is loaded when the enclosing Rocq module is :cmd:`Import`-ed.

Build directives
################

Build directives are special attributes that control how the OCaml code is compiled.

.. attr:: libraries( {+, @package } )
   :name: libraries

   Links the given libraries before the OCaml snippet.

.. attr:: ppx( {+, @package } )

   Applies a list of preprocessors to the OCaml code.

   .. example::

      One can use `ppx_deriving` to automatically derive printers for a type:

      .. coq::

         #[ppx="ppx_deriving.show"]
         Camltac Module M := ocaml:{{
           type t = A | B [@@deriving show { with_path = false }]
         }}.

         Camltac Eval ocaml:(return M.(show A)). (* .unfold *)
         
.. attr:: compiler( {+, @compiler-flag } )

   Pass the given compilation arguments to the compiler.
