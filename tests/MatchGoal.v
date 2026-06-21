From Camltac Require Import Camltac.

Goal forall x y z : nat, True.
Proof.
  intros.
  ocaml:{{
    match%goal __ with
    | { h = _ :: "nat" }, _ ->
      let name = Names.Id.to_string h in
      Feedback.msg_notice (Pp.str name);
      return ()
  }}.
  ocaml:{{
    match%goal reverse with
    | { h = _ :: "nat" }, _ ->
      let name = Names.Id.to_string h in
      Feedback.msg_notice (Pp.str name);
      return ()
  }}.
  exact I.
Qed.
