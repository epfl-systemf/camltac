.. _runtime:

Camltac's runtime
=================

The runtime consists in a set of modules that Camltac snippets can read and write to, so that Camltac can fetch their output. It is in fact the only way to obtain values from loaded snippets, since :ref:`dynamic linking <dynamic-linking>` does not allow us to reference loaded values from Camltac code.

Environment (`Runtime.Environment`)
-----------------------------------

The environment is a mapping from identifiers to :ltac2-type:`preterm`, used for correctly globalizing snippets. Indeed, snippets that are reloaded from a different file may have a different global environment, and hence would globalize differently.

To fix this issue, `preterm` and `constr` quotations generate calls to `Runtime.Environment.persist`, which either fetches the value from the environment (if it exists), or stores a new one. This way, we can capture the environment obtained at the end of the original load and use it when loading the snippet from other files.

Below is an example of the output of `ppx_rocq` on a `constr` quotation:

.. hlist::
   :columns: 2

   * .. code-block:: coq
        :caption: Output of `ppx_rocq` (simplified)
        :linenos:
        :emphasize-lines: 3

        open struct
          let preterm__000_ =
            Runtime.Environment.persist ~id:"File.v:1"
              (fun () ->
                Ppx_rocq_runtime.Parsing.glob_constr_of_string
                  ~loc:(* … *)
                  {| 1 + 1 |})
        end

        (* … *)

   * .. code-block:: coq
        :caption: Original code (`File.v`)
        :emphasize-lines: 1

        {%constr| 1 + 1 |}

Output (`Runtime.Output`)
-------------------------

The `Output` module is used as a shared location for snippets to write their output, and for Camltac to retrieve it. For example, `Camltac Eval` tactics are written using `Runtime.Output.set_tactic`, and Camltac fetches them using `Runtime.Output.get_tactic`.
