(lang dune 3.22)
(using rocq 0.12)

(package
 (name mltac)
 (synopsis "OCaml as a Tactic Language for Rocq")
 (depends
   rocq-core
   rocq-runtime
   ppx_rocq
   dynlink))
