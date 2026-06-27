From Camltac Require Import Camltac.

Goal forall x y z : nat, True.
Proof.
  intros.
  ocaml:{{
    match%rocq goal with
    | { h = _ :: "nat" }, _ ->
      let name = Names.Id.to_string h in
      Feedback.msg_info (Pp.str name);
      return ()
  }}.
  ocaml:{{
    match%rocq reverse goal with
    | { h = _ :: "nat" }, _ ->
      let name = Names.Id.to_string h in
      Feedback.msg_info (Pp.str name);
      return ()
  }}.
  exact I.
Qed.
