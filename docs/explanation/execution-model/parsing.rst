Parsing
=======

To compile OCaml code, Camltac must first recognize OCaml code in Rocq files and write it to a build file.

Parsing OCaml code
------------------

Camltac does not parse OCaml itself. Instead, it relies on Rocq's extensible parser to recognize quotations of the form ``ocaml:(…)``, ``ocaml:{…}``, ``ocaml:{{…}}``, etc. Rocq's lexer produces a single `QUOTATION "ocaml:"` token for the whole quotation, without looking at its contents, so the OCaml code is never interpreted as Rocq syntax.

.. _scaffolding:

Scaffolding
-----------

*Scaffolding* is the operation of taking the user's code and wrapping it in the appropriate boilerplate, so that the code executes correctly. This broadly includes:

* Adding source location information (through `line number directives`_);
* Adding type constraints (e.g. :cmd:`Camltac Eval` expects values of type `a tactic` for some `a`);
* Adding module aliases (to be able to reference previous modules by their name);
* Registering outputs through the :ref:`runtime <runtime>`.

For example, here is the output of scaffolding a `Camltac Eval` statement:

.. hlist::
   :columns: 2

   * .. code-block:: coq
        :caption: Scaffolded code
        :linenos:
        :emphasize-lines: 3, 10
        
        # 1 "_scaffold_"
        open struct
          module A = (* … *)
        end
        
        type t = int [@@deriving show]
        
        let () = Runtime.Output.set_tactic begin
        # 41 "File.v"
                            return 1
        # 11 "_scaffold_"
        end

   * .. code-block:: coq
        :caption: Original code (`File.v`)
        :linenos:
        :lineno-start: 40
        :emphasize-lines: 1, 4

        Camltac Module A := ocaml:{{ (* … *) }}.
         
        (* … *)
        Camltac Eval ocaml:(return 1).


.. _line number directives: https://ocaml.org/manual/5.5/lex.html#sss:lex-linedir
