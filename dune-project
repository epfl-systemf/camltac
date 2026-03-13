(lang dune 3.21)
(using rocq 0.11)

(package
 (name mltac)
 (synopsis "OCaml as a Tactic Language for Rocq")
 (depends
   rocq-core
   rocq-runtime
   dynlink))
