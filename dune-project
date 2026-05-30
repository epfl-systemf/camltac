(lang dune 3.22)
(using rocq 0.12)

(name camltac)

(generate_opam_files true)

(authors "Dario Halilovic")
(maintainers "Dario Halilovic")

(homepage "https://github.com/epfl-systemf/camltac")
(source
 (github epfl-systemf/camltac))
(bug_reports "https://github.com/epfl-systemf/camltac/issues")

(package
 (name camltac)
 (synopsis "OCaml as a Tactic Language for Rocq")
 (depends
   rocq-core
   rocq-runtime
   ppx_rocq
   sexplib
   ppx_sexp_conv))

(package
 (name camltac-examples)
 (synopsis "A collection of examples using Camltac")
 (depends
   camltac
   rocq-stdlib
   rocq-stdpp))
