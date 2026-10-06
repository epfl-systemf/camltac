`Camltac Run`
=============

.. coq:: none

   Require Import Camltac.Camltac.

.. cmd:: {? @attributes } Camltac Run @ocaml .
   :name: Camltac Run

   Compiles and runs the given OCaml code in the current Rocq state.

   .. attr:: @attributes
      :name: attributes

      Locality attributes and build directives.

      .. warning::
   
         OCaml code that mutates Rocq's global state, such as using `Summary.ref`, should not be made non-`local`,
         since their effects would be performed multiple times:
   
         .. coq::
   
            Module M.
              #[export]
              Camltac Run ocaml:{{
                let _ = Summary.ref ~name:"test-value" 0
              }}.
            End M.
   
            Fail Import M. (* .fails .unfold *)
   
      
