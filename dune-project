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
 (depends
   (ocaml (>= 4.14))
   (dune (< 3.24))
   (coq-core (>= 9.0))
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
