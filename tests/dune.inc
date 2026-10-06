
(rule
 (targets Backtrack.output)
 (deps Backtrack.v (package camltac))
 (action
  (setenv OCAMLPATH %{project_root}/../install/default/lib
   (with-stdout-to Backtrack.output
    (run coqc -q -Q ../theories Camltac -R . Camltac.Tests Backtrack.v)))))

(rule
 (alias runtest)
 (action (diff Backtrack.expected Backtrack.output)))

(rule
 (targets Check.output)
 (deps Check.v (package camltac))
 (action
  (setenv OCAMLPATH %{project_root}/../install/default/lib
   (with-stdout-to Check.output
    (run coqc -q -Q ../theories Camltac -R . Camltac.Tests Check.v)))))

(rule
 (alias runtest)
 (action (diff Check.expected Check.output)))

(rule
 (targets Eval.output)
 (deps Eval.v (package camltac))
 (action
  (setenv OCAMLPATH %{project_root}/../install/default/lib
   (with-stdout-to Eval.output
    (run coqc -q -Q ../theories Camltac -R . Camltac.Tests Eval.v)))))

(rule
 (alias runtest)
 (action (diff Eval.expected Eval.output)))

(rule
 (targets InProof.output)
 (deps InProof.v (package camltac))
 (action
  (setenv OCAMLPATH %{project_root}/../install/default/lib
   (with-stdout-to InProof.output
    (run coqc -q -Q ../theories Camltac -R . Camltac.Tests InProof.v)))))

(rule
 (alias runtest)
 (action (diff InProof.expected InProof.output)))

(rule
 (targets MatchGoal.output)
 (deps MatchGoal.v (package camltac))
 (action
  (setenv OCAMLPATH %{project_root}/../install/default/lib
   (with-stdout-to MatchGoal.output
    (run coqc -q -Q ../theories Camltac -R . Camltac.Tests MatchGoal.v)))))

(rule
 (alias runtest)
 (action (diff MatchGoal.expected MatchGoal.output)))

(rule
 (targets Module.output)
 (deps Module.v (package camltac))
 (action
  (setenv OCAMLPATH %{project_root}/../install/default/lib
   (with-stdout-to Module.output
    (run coqc -q -Q ../theories Camltac -R . Camltac.Tests Module.v)))))

(rule
 (alias runtest)
 (action (diff Module.expected Module.output)))

(rule
 (targets Run.output)
 (deps Run.v (package camltac))
 (action
  (setenv OCAMLPATH %{project_root}/../install/default/lib
   (with-stdout-to Run.output
    (run coqc -q -Q ../theories Camltac -R . Camltac.Tests Run.v)))))

(rule
 (alias runtest)
 (action (diff Run.expected Run.output)))
