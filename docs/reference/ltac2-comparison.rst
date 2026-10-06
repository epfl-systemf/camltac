=====================
Comparison with Ltac2
=====================

The tables below map Ltac2 constructs to their equivalent in Camltac.

Types
=====

Type declarations
-----------------

+------------------------------------------+----------------------------------------+
| Ltac2                                    | OCaml                                  |
+==========================================+========================================+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    Ltac2 Type t := int.                  |    type t = int                        |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    Ltac2 Type rec nat := [O | S (nat)].  |    type nat = O | S of nat             |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    Ltac2 Type flag := {                  |    type flag = { mutable used: bool }  |
|      mutable used : bool                 |                                        |
|    }.                                    |                                        |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    Ltac2 Type rec tree :=                |    type tree = Node of nat * forest    |
|      [Node (nat, forest)]                |    and forest =                        |
|    with forest :=                        |    | Leaf of nat                       |
|      [Leaf (nat) | Cons (tree, forest)]. |    | Cons of tree * forest             |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    Ltac2 Type exn ::=                    |    exception My_error of string        |
|      [ My_error (string) ].              |                                        |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    Ltac2 Import Type nat as n.           |    type n = nat                        |
|                                          |                                        |
+------------------------------------------+----------------------------------------+

Built-in types
--------------

Here is a mapping between Ltac2 built-in types and their OCaml counterpart.

The following types are re-exported by the `Ltac2` module, e.g. ``Ltac2.ident`` is an alias for ``Names.Id.t``:

.. list-table::
   :header-rows: 1

   * - Ltac2
     - OCaml
   * - :ltac2-type:`ident`
     - ``Names.Id.t``
   * - :ltac2-type:`evar`
     - ``Evar.t``
   * - :ltac2-type:`cast`
     - ``Constr.cast_kind``
   * - :ltac2-type:`constant`
     - ``Constant.t``
   * - :ltac2-type:`inductive`
     - ``Ind.t``
   * - :ltac2-type:`constructor`
     - ``Construct.t``
   * - :ltac2-type:`projection`
     - ``Projection.t``
   * - :ltac2-type:`pattern`
     - ``Pattern.constr_pattern``
   * - :ltac2-type:`constr`
     - ``EConstr.t``
   * - :ltac2-type:`preterm`
     - ``Ltac_pretype.closed_glob_constr``
   * - :ltac2-type:`binder`
     - ``Name.t EConstr.binder_annot * EConstr.types``
   * - :ltac2-type:`message`
     - ``Pp.t``
   * - :ltac2-type:`reference`
     - ``GlobRef.t``
   * - :ltac2-type:`err`
     - ``Exninfo.iexn``
   * - :ltac2-type:`iexn`
     - ``Exninfo.iexn``
   * - :ltac2-type:`exninfo`
     - ``Exninfo.info``

The other types have no alias in the `Ltac2` module and are used directly through their OCaml type:

+--------------+-------------------------+
| Ltac2        | OCaml                   |
+==============+=========================+
| ``'a array`` | ``'a array``            |
+--------------+-------------------------+
| ``int``      | ``int``                 |
+--------------+-------------------------+
| ``string``   | ``string``              |
+--------------+-------------------------+
| ``char``     | ``char``                |
+--------------+-------------------------+
| ``exn``      | ``Ltac2.iexn``          |
+--------------+-------------------------+
| ``uint63``   | ``Uint63.t``            |
+--------------+-------------------------+
| ``float``    | ``Float64.t``           |
+--------------+-------------------------+
| ``pstring``  | ``Pstring.t``           |
+--------------+-------------------------+
| ``meta``     | ``Constr.metavariable`` |
+--------------+-------------------------+
| ``sort``     | ``Sorts.t``             |
+--------------+-------------------------+
| ``instance`` | ``EConstr.EInstance.t`` |
+--------------+-------------------------+


Term syntax
===========

+------------------------------------------+----------------------------------------+
| Ltac2                                    | OCaml                                  |
+==========================================+========================================+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    fun x : nat => x                      |    fun (x : nat) -> x                  |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    let x := y in z                       |    let x = y in z                      |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            |                                        |
|                                          |                                        |
|    &x                                    |   Not implemented. `Submit a PR`_      |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    @x                                    |    {%ident| x |}                       |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    ident:(x)                             |    {%ident| x |}                       |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    reference:(Nat.add)                   |    Env.expand {%qualid| Nat.add |}     |
|                                          |    (* returns a list of references *)  |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    constr:(S (S 0))                      |    {%constr| S (S 0) |}                |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    let x := constr:(0) in                |    let* x = {%constr| 0 |} in          |
|    constr:(1 + $x)                       |    {%constr| 1 + %{x} |}               |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    open_constr:(1 + _) (* or '(1 + _) *) |    {%open_constr| 1 + _ |}             |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    preterm:(x)                           |    {%preterm| x |}                     |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            |                                        |
|                                          |                                        |
|    pat:(?n + ?m)                         |    Not implemented. `Submit a PR`_     |
|                                          |                                        |
+------------------------------------------+----------------------------------------+



Pattern matching
================

+------------------------------------------+------------------------------------------+
| Ltac2                                    | OCaml                                    |
+==========================================+==========================================+
| .. code:: coq                            | .. code:: ocaml                          |
|                                          |                                          |
|    match! … with                         |    match%rocq … with                     |
|                                          |                                          |
+------------------------------------------+------------------------------------------+
| .. code:: coq                            | .. code:: ocaml                          |
|                                          |                                          |
|    lazy_match! … with                    |    match%lazy … with                     |
|                                          |                                          |
+------------------------------------------+------------------------------------------+
| .. code:: coq                            | .. code:: ocaml                          |
|                                          |                                          |
|    multi_match! … with                   |    match%multi … with                    |
|                                          |                                          |
+------------------------------------------+------------------------------------------+
| .. code:: coq                            | .. code:: ocaml                          |
|                                          |                                          |
|    lazy_match! constr:(S 0) with         |    match%lazy {|S 0|} with               |
|    | S ?n => n                           |    | {|S ?n|} -> return n                |
|    | _ => Control.zero Not_found         |    | _ -> Ltac2.Control.zero             |
|    end.                                  |      (Not_found, Exninfo.null)           |
|                                          |                                          |
+------------------------------------------+------------------------------------------+
| .. code:: coq                            | .. code:: ocaml                          |
|                                          |                                          |
|    match! constr:(S 0) with              |    match%rocq {|S 0|} with               |
|    | S ?n => n                           |    | {|S ?n|} -> return n                |
|    | _ => Control.zero Not_found         |    | _ -> Ltac2.Control.zero             |
|    end.                                  |      (Not_found, Exninfo.null)           |
|                                          |                                          |
+------------------------------------------+------------------------------------------+
| .. code:: coq                            | .. code:: ocaml                          |
|                                          |                                          |
|    multi_match! constr:(S 0) with        |    match%multi {|S 0|} with              |
|    | S ?n => n                           |    | {|S ?n|} -> return n                |
|    | _ => Control.zero Not_found         |    | _ -> Ltac2.Control.zero             |
|    end.                                  |      (Not_found, Exninfo.null)           |
|                                          |                                          |
+------------------------------------------+------------------------------------------+
| .. code:: coq                            | .. code:: ocaml                          |
|                                          |                                          |
|    lazy_match! goal with                 |    match%lazy goal with                  |
|    | [ H : _ |- _ ] => apply H           |    | { h = _ }, _ ->                     |
|    end.                                  |      let* env in                         |
|                                          |      let h = Ltac2.Control.hyp env h in  |
|                                          |      apply [term h]                      |
|                                          |                                          |
+------------------------------------------+------------------------------------------+
| .. code:: coq                            | .. code:: ocaml                          |
|                                          |                                          |
|    match! reverse goal with              |    match%rocq reverse goal with          |
|    | [ H : _ |- _ ] => apply H           |    | { h = _ }, _ ->                     |
|    end.                                  |      let* env in                         |
|                                          |      let h = Ltac2.Control.hyp env h in  |
|                                          |      apply [term h]                      |
|                                          |                                          |
+------------------------------------------+------------------------------------------+

Vernacular commands
===================

+------------------------------------------+----------------------------------------+
| Ltac2                                    | Camltac                                |
+==========================================+========================================+
| .. code:: coq                            | .. code:: coq                          |
|                                          |                                        |
|    Ltac2 Eval f ().                      |    Camltac Eval ocaml:(f ()).          |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: coq                          |
|                                          |                                        |
|    Ltac2 Check f ().                     |    Camltac Check ocaml:(f ()).         |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            |                                        |
|                                          |                                        |
|    Ltac2 Globalize e.                    | No equivalent.                         |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. hlist::                             |
|                                          |    :columns: 2                         |
|    Print Ltac2 M.                        |                                        |
|                                          |    * .. code:: coq                     |
|                                          |                                        |
|                                          |         Camltac Check M.               |
|                                          |                                        |
|                                          |    * [#sig]_                           |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            |                                        |
|                                          |                                        |
|    Print Ltac2 Type f.                   | Not implemented. `Submit a PR`_        |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            |                                        |
|                                          |                                        |
|    Print Ltac2 Signatures.               | Not implemented. `Submit a PR`_        |
|                                          |                                        |
+------------------------------------------+----------------------------------------+

.. [#sig] Only prints the signature.

Definition commands
-------------------

+------------------------------------------+----------------------------------------+
| Ltac2                                    | Camltac                                |
+==========================================+========================================+
| .. code:: coq                            | .. code:: coq                          |
|                                          |                                        |
|    Ltac2 f := fun x => x.                |    Camltac Module M := ocaml:(         |
|                                          |      let f x = x                       |
|                                          |    ).                                  |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            |                                        |
|                                          |                                        |
|    Ltac2 Notation "foo" := ….            | No equivalent.                         |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
|                                          | .. code:: coq                          |
|                                          |                                        |
| No equivalent.                           |    Camltac Load "M.ml".                |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
|                                          | .. code:: coq                          |
|                                          |                                        |
| No equivalent.                           |    Camltac Run ocaml:(…).              |
|                                          |                                        |
+------------------------------------------+----------------------------------------+

Tacticals
=========

+------------------------------------------+----------------------------------------+
| Ltac2                                    | OCaml                                  |
+==========================================+========================================+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    let x := tac1 () in tac2              |    let* x = tac1 () in tac2            |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    tac1; tac2                            |    tac1 >> tac2                        |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    tac1 || tac2                          |    tac1 <||> tac2                      |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    tac1 + tac2                           |    tac1 <+> tac2                       |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    try tac                               |    try_ tac                            |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    repeat tac                            |    repeat tac                          |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    do 2 tac                              |    repeat ~n:2 tac                     |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    progress tac                          |    progress tac                        |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    first [ tac1 | tac2 ]                 |    first [tac1; tac2]                  |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    solve [ tac1 | tac2 ]                 |    solve [tac1; tac2]                  |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    once tac                              |    once tac                            |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    tac > [ tac1 | tac2 ]                 |    dispatch tac [tac1; tac2]           |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    time tac                              |    time tac                            |
|                                          |    (* or: time ~name:"foo" tac *)      |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    Control.timeout 5                     |    timeout 5 tac                       |
|      (fun () => tac)                     |                                        |
|                                          |                                        |
+------------------------------------------+----------------------------------------+
| .. code:: coq                            | .. code:: ocaml                        |
|                                          |                                        |
|    abstract tac                          |    abstract tac                        |
|                                          |                                        |
+------------------------------------------+----------------------------------------+


.. _Submit a PR: https://github.com/epfl-systemf/camltac/pulls
