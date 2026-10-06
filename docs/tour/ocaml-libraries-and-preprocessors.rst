Using OCaml libraries and preprocessors
=======================================

.. coq:: none

   Require Import Camltac.Camltac.

Camltac supports additional OCaml libraries and preprocessors through special Rocq attributes:

- The `#[libraries]` attribute allows one to use extra OCaml libraries (see `examples/ParallelTactics.v`_).

- The `#[ppx]` attribute is used to specify additional preprocessors, such as `ppx_deriving_yojson`:

.. coq::

   #[ppx(ppx_deriving_yojson)]
   Camltac Module Op := ocaml:{{
     (** Here's the type of expressions in a simple lambda calculus.
         [ppx_deriving_yojson] derives JSON conversions methods. *)
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
   }}. (* .unfold *)

Both `#[libraries]` and `#[ppx]` expect a list of packages that are installed on your machine. Camltac is not a package manager however, so you should make sure to list these packages as proper dependencies in your build system.

.. _examples/ParallelTactics.v: https://github.com/epfl-systemf/camltac/tree/main/examples/ParallelTactics.v
