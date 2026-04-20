(** This file is the main entry point of the PPX executable.

    We generate an executable similar to the one used by Dune, so that we can apply
    the transformations manually on the code snippets. There are two approaches to
    pre-processing:

    1. The first approach is the “classic” approach, where pre-processing is
       performed by the OCaml compiler as part of the compilation pipeline. This
       approach relies on the [-pp] and [-ppx] hooks in the compiler, which perform
       source-to-source and AST-to-AST transformations, respectively.

    2. The second approach runs the pre-processing as a separate pipeline, saving
       its output before compilation.

    We follow here the second approach, which is the approach taken by Dune in
    their {{:https://dune.readthedocs.io/en/stable/explanation/preprocessing.html} “fast pipeline”}.
 *)

let () =
  (** This command generates a standalone executable that pre-processes input files.
      The executable includes an OCaml parser. *)
  Ppxlib.Driver.standalone ()
