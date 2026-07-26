(*|
=================
A tour of Camltac
=================

In this tour, we'll go over each of the features that Camltac proposes through a series of small examples. At the end of this tour, you'll be able to write tactics in Camltac like in Ltac2, but also meta-programs that use extra OCaml libraries or advanced features of Rocq.
|*)

Require Import Camltac.Camltac.

(*|
Running OCaml code
==================

At its core, Camltac provides a way to run OCaml code within Rocq files. Following the tradition in the programming community, let's print "Hello world!":
|*)

Camltac Run ocaml:{{
  Feedback.msg_info (Pp.str "Hello world!")
}}.

(*|
Camltac recognizes OCaml syntax embedded between `{{` and `}}`, and interprets it as top-level OCaml expressions (i.e. the same expressions that you would put in an `.ml` file). This means, for example, that you can use `let` bindings:
|*)

Camltac Run ocaml:{{
  let hello = "Hello"
  let world = " wonderful world!"

  let () = Feedback.msg_info (Pp.str (hello ^ world))
}}.

(*|
Here, `hello` and `world` cannot be accessed outside of the curly braces. To expose them, you need to define a _module_:
|*)

Camltac Module M := ocaml:{{
  let hello = "Hello"
  let world = " from module M!"
}}.

Camltac Run ocaml:{{
  Feedback.msg_info (Pp.str (M.hello ^ M.world))
}}.

(*|
Camltac can also load external `.ml` files:
|*)

Camltac Load "file.ml".

(*|
The `Camltac Load "file.ml"` command behaves equivalently to `Camltac Module File := ocaml:(<contents of file.ml>)`.

Note that when using Dune, `file.ml` must be copied to the `_build` directory, which can be achieved using the following rule:
```dune
(rule
 (targets _dummy.v)
 (deps file.ml) ;; or (glob_files *.ml)
 (action (write-file _dummy.v "")))
```
It is important that the dummy target is a `.v` file, so that it runs before the `rocq.theory` stanza.

Defining new tactics
====================

In Camltac, tactics are OCaml functions whose return type is `t tactic` (for some type `t`):
|*)

Camltac Module Print_conclusion := ocaml:{{
  let run () =
    let* goals = Proofview.Goal.goals in
    match goals with
    | [goal] ->
      let* goal in
      let conclusion = Proofview.Goal.concl goal in
      let* pp = Terms.Constr.print conclusion in
      Feedback.msg_info pp;
      return ()
    | _ ->
      fail (Pp.str "No goal focussed")
}}.

(*|
To run our tactic, we can use the `ocaml:` quotation in Ltac (and Ltac2):
|*)

Goal forall x : nat, x = x.
Proof.
  ocaml:(Print_conclusion.run ()).
  reflexivity.
Qed.

(*|
…or use `Camltac Eval`, which evaluates a tactic and prints its result:
|*)

Camltac Eval ocaml:(return (1 + 1)).

(*|
Similarly to `Ltac2 Eval`, `Camltac Eval` does not modify the current proof state.

Quotations
==========

Camltac provides quotations of the form `{%name| … |}` to input Rocq terms in OCaml. For example, to obtain a well-typed term, one can use the `%constr` quotation:
|*)

Camltac Eval ocaml:({%constr| forall x : nat, x = x |}).

(*|
`%constr` is the equivalent of Ltac2's `constr:` quotation, with similar semantics.

Other quotations include `%open_constr` for well-typed terms with holes, `%preterm` for untyped terms, `%expr` for concrete syntax, and `%ident` for identifiers.

Antiquotations
==============

An antiquotation is a part of a quotation that is computed by an OCaml expression. In Camltac, they are written using the `%{…}` syntax:
|*)

Camltac Eval ocaml:{{
  let* lhs = {%constr| 1 + 1 |} in
  let* rhs = {%constr| 2 |} in
  {%constr| %{lhs} = %{rhs} |}
}}.

(*|
Unlike the Ltac2 `$` antiquotations, the antiquoted expression between the curly braces does not have to be a variable, and any well-typed OCaml expression is allowed.

Pattern matching over terms
===========================

Just like Ltac2, Camltac provides the ability to perform pattern-matching on terms using the `match%rocq` syntax:
|*)

Inductive nat' :=
  | NatZero
  | NatSucc (n : nat')
  | NatMul (n1 n2 : nat').

Camltac Module Reify := ocaml:{{
  let rec reify n =
    match%rocq n with
    | {| 0 |} -> {%constr| NatZero |}
    | {| S ?m |} ->
      let* m' = reify m in
      {%constr| NatSucc %{m'} |}
    | {| ?n1 * ?n2 |} ->
      let* n1' = reify n1 in
      let* n2' = reify n2 in
      {%constr| NatMul %{n1'} %{n2'} |}
}}.

Camltac Eval ocaml:{{
  let* n = {%constr| 2 * 3 |} in
  Reify.reify n
}}.

(*|
The left-hand side of each branch is a pattern with pattern variables of the form `?name`. Each pattern variable is associated to an OCaml variable of the same name, which makes the syntax similar to Ltac2's `match!`.

Note that `match%rocq` is backtracking, meaning that branches are tried in order until one of them succeeds. We also support `match%lazy` and `match%multi` for non-backtracking and multi-success pattern matching, as in Ltac2.

Pattern matching over goals
===========================

Pattern matching over goal is implemented by the `match%rocq goal with` syntax:
|*)

Camltac Module My_tauto := ocaml:{{
  let run () =
    let* () = intros () in
    repeat begin match%rocq goal with
    | { h = _ :: {| _ -> ?b |} }, {| ?b |} ->
       let* env in
       let h = Result.get_ok (Ltac2.Control.hyp env h) in
       apply [(h, NoBindings)]
    | _, {| _ \/ _ |} ->
       Ltac2.Control.plus (left ()) (fun _ -> right ())
    | _, _ ->
       assumption ()
    end
}}.

Goal forall A B C, (C -> A) -> C -> A \/ B.
Proof.
  ocaml:(My_tauto.run ()).
Qed.

(*|
Using OCaml libraries and preprocessors
=======================================

Camltac supports additional OCaml libraries and preprocessors through special floating attributes:

- The `[@@@using]` attribute allows one to use extra OCaml libraries (see `ParallelTactics.v` for an example)

- The `[@@@ppx]` attribute is used to specify additional preprocessors, such as `ppx_deriving_yojson`:
|*)

Camltac Module Op := ocaml:{{
  [@@@ppx "ppx_deriving_yojson"]

  (** Here's the type of expressions in a simple lambda calculus.
      [ppx_deriving_yojson] automatically derives JSON conversions methods for us. *)
  type t =
    | Var of string
    | Abs of { x: string; body: t }
    | App of (t * t)
  [@@deriving yojson]
}}.

Camltac Run ocaml:{{
  open Op

  (* λx. x *)
  let id = Abs { x = "x"; body = Var "x" }

  let () =
    let s = Yojson.Safe.to_string (to_yojson id) in
    Feedback.msg_info (Pp.str s)
}}.

(*|
Both `[@@@using]` and `[@@@ppx]` expect a comma-separated list of packages that are installed on your machine. Camltac is not a package manager however, so you should make sure to list these packages as proper dependencies in your build system.

Interoperability with Ltac2
===========================

Tactics in Camltac can be exposed to Ltac2 using the `FFI` module:
|*)

Require Import Ltac2.Ltac2.

Camltac Run ocaml:{{
  (* We expose our previously defined reification procedure to Ltac2: *)
  Ltac2.FFI.(define "reify"
              (constr @-> tac constr) (* Type specification; see [Tac2externals] in Rocq's Ltac2 plugin. *)
              Reify.reify)
}}.

Ltac2 @external reify : constr -> constr :=
  "camltac.plugin.runtime" "reify".

Ltac2 Eval (reify constr:(2 * 3)).

(*|
Accessing internal Rocq APIs
============================

Camltac provides full access to Rocq's internal APIs, since the OCaml code runs in the Rocq process. This allows us to access Rocq's latest features, query Rocq for detailed information, or implement features traditionally reserved to OCaml plugins.

For example, here's an implementation of a simple mutable counter that follows backtracks using Rocq's [Summary] module:
|*)

Camltac Module Counter := ocaml:{{
  let value = Summary.ref ~stage:Interp ~name:"counter" 0

  let inc () =
    value := !value + 1
  let print () =
    Feedback.msg_info (Pp.int !value)
}}.

(*|
Try it out for yourself: run over these snippets, and backtrack to see the effect!
|*)

Camltac Run ocaml:(Counter.print ()). (* 0 *)
Camltac Run ocaml:(Counter.inc ()).
Camltac Run ocaml:(Counter.print ()). (* 1 *)

(*|
Congrats, you reached the end of this tour!

There are several more examples of what Camltac can offer in this directory — make sure check to them out!
|*)
