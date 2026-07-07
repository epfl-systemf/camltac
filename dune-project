(lang dune 3.22)
(using rocq 0.12)

(name camltac)

(generate_opam_files true)

(authors "Dario Halilovic")
(maintainers "Dario Halilovic")
(license LGPL-2.1-only)

(homepage "https://github.com/epfl-systemf/camltac")
(source
 (github epfl-systemf/camltac))
(bug_reports "https://github.com/epfl-systemf/camltac/issues")

(package
 (name camltac)
 (synopsis "OCaml as a Tactic Language for Rocq")
 (depends
   (ocaml (>= 5.4))
   (dune (< 3.24))
   rocq-runtime
   ppx_rocq
   ppx_deriving ;; For Camltac Eval
   ocamlfind
   camltac-directives))

(package
 (name camltac-directives)
 (synopsis "A small preprocessor that handles build directives for Camltac")
 (depends
   ppxlib
   ocamlfind
   sexplib
   ppx_sexp_conv))

(package
 (name camltac-examples)
 (synopsis "A collection of examples using Camltac")
 (depends
   camltac
   rocq-stdlib
   rocq-stdpp
   ppx_minidebug
   eio_main))
