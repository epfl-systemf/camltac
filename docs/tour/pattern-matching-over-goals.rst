Pattern matching over goals
===========================

.. coq:: none

   Require Import Camltac.Camltac.

Pattern matching over goals is implemented by the `match%rocq goal with` syntax:

.. coq::

   Camltac Module My_tauto := ocaml:{{
     let run () =
       let* () = intros [] in
       let open Ltac2 in
       repeat begin match%rocq goal with
       | { h = _ :: {| _ -> ?b |} }, {| ?b |} ->
          let* env in
          let h = Control.hyp env h in
          apply [term h]
       | _, {| _ \/ _ |} ->
          Control.plus (left ()) (fun _ -> right ())
       | _, _ ->
          assumption ()
       end
   }}.

   Goal forall A B C, (C -> A) -> C -> A \/ B.
   Proof.
     ocaml:(My_tauto.run ()).
   Qed.
