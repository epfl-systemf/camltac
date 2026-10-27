(lang dune 3.17)
(using coq 0.10)
(using directory-targets 0.1)

(name rocq-camltac)

(generate_opam_files true)
(subst disabled) ;; Work-around for Dune 3.17 subst bug: https://github.com/ocaml/dune/issues/11045

(authors "Dario Halilovic")
(maintainers "Dario Halilovic")
(license LGPL-2.1-only)

(homepage "https://github.com/epfl-systemf/camltac")
(source
 (github epfl-systemf/camltac))
(bug_reports "https://github.com/epfl-systemf/camltac/issues")

(package
 (name rocq-camltac)
 (synopsis "OCaml as a Tactic Language for Rocq")
 (description
   "Camltac is an OCaml plugin for Rocq that lets you run OCaml code \
within Rocq scripts. Camltac makes it possible to define OCaml \
meta-programs and tactics, and run them in the current Rocq state \
without the friction and boilerplate of setting up a plugin.

Camltac is both a tactic and a meta-programming language:

- As a tactic language, Camltac provides constructs inspired by Ltac2, \
  including term quotations (`{%constr| … |}`), pattern matching (`match%rocq`), \
  and antiquotations using ppx_rocq. Camltac makes it easy to define new \
  tactics by providing the usual tacticals from Ltac2, and a dedicated \
  FFI with Ltac and Ltac2.

- As a meta-programming language, Camltac offers a complete meta-programming \
  experience by allowing access to Rocq's internal APIs and state. To ensure \
  stability, Camltac includes the Ltac2 APIs which provide a simple entry \
  point to meta-programming in OCaml.")
 (tags
  ("category:Miscellaneous/Rocq Extensions"
   "keyword:tactic"
   "keyword:ocaml"
   "keyword:ltac2"
   "logpath:Camltac"
   "date:2026-10-26"))
 (depends
   (ocaml (>= 4.14))
   (dune (< 3.24))
   (coq-core (>= 9.0))
   rocq-core
   ppx_rocq
   rocq-mltac2
   ppx_deriving ;; For Camltac Eval
   ocamlfind))

(package
 (name rocq-camltac-tests)
 (synopsis "Camltac's test suite")
 (depends
   rocq-camltac
   rocq-stdlib))

(package
 (name rocq-camltac-examples)
 (synopsis "A collection of examples using Camltac")
 (depends
   rocq-camltac
   rocq-stdlib
   rocq-stdpp
   ppx_minidebug
   ppx_deriving_yojson
   eio_main))
