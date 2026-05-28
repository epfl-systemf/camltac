(lang dune 3.22)
(using rocq 0.12)

(generate_opam_files true)

(package
 (name camltac)
 (synopsis "OCaml as a Tactic Language for Rocq")
 (depends
   rocq-core
   rocq-runtime
   ppx_rocq))
