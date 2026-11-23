
(rule
 (targets Alerts.output)
 (deps Alerts.v _dummy_target.v (package rocq-camltac))
 (action
  (with-stdout-to Alerts.output
   (system "mkdir -p .expected && rocq c -q -Q ../theories Camltac -R . Camltac.Tests -o .expected/Alerts.vo Alerts.v"))))

(rule
 (alias runtest)
 (action (diff Alerts.expected Alerts.output)))

(rule
 (targets Backtrack.output)
 (deps Backtrack.v _dummy_target.v (package rocq-camltac))
 (action
  (with-stdout-to Backtrack.output
   (system "mkdir -p .expected && rocq c -q -Q ../theories Camltac -R . Camltac.Tests -o .expected/Backtrack.vo Backtrack.v"))))

(rule
 (alias runtest)
 (action (diff Backtrack.expected Backtrack.output)))

(rule
 (targets Check.output)
 (deps Check.v _dummy_target.v (package rocq-camltac))
 (action
  (with-stdout-to Check.output
   (system "mkdir -p .expected && rocq c -q -Q ../theories Camltac -R . Camltac.Tests -o .expected/Check.vo Check.v"))))

(rule
 (alias runtest)
 (action (diff Check.expected Check.output)))

(rule
 (targets Eval.output)
 (deps Eval.v _dummy_target.v (package rocq-camltac))
 (action
  (with-stdout-to Eval.output
   (system "mkdir -p .expected && rocq c -q -Q ../theories Camltac -R . Camltac.Tests -o .expected/Eval.vo Eval.v"))))

(rule
 (alias runtest)
 (action (diff Eval.expected Eval.output)))

(rule
 (targets InProof.output)
 (deps InProof.v _dummy_target.v (package rocq-camltac))
 (action
  (with-stdout-to InProof.output
   (system "mkdir -p .expected && rocq c -q -Q ../theories Camltac -R . Camltac.Tests -o .expected/InProof.vo InProof.v"))))

(rule
 (alias runtest)
 (action (diff InProof.expected InProof.output)))

(rule
 (targets Load.output)
 (deps Load.v _dummy_target.v (package rocq-camltac))
 (action
  (with-stdout-to Load.output
   (system "mkdir -p .expected && rocq c -q -Q ../theories Camltac -R . Camltac.Tests -o .expected/Load.vo Load.v"))))

(rule
 (alias runtest)
 (action (diff Load.expected Load.output)))

(rule
 (targets Ltac2.output)
 (deps Ltac2.v _dummy_target.v (package rocq-camltac))
 (action
  (with-stdout-to Ltac2.output
   (system "mkdir -p .expected && rocq c -q -Q ../theories Camltac -R . Camltac.Tests -o .expected/Ltac2.vo Ltac2.v"))))

(rule
 (alias runtest)
 (action (diff Ltac2.expected Ltac2.output)))

(rule
 (targets MatchGoal.output)
 (deps MatchGoal.v _dummy_target.v (package rocq-camltac))
 (action
  (with-stdout-to MatchGoal.output
   (system "mkdir -p .expected && rocq c -q -Q ../theories Camltac -R . Camltac.Tests -o .expected/MatchGoal.vo MatchGoal.v"))))

(rule
 (alias runtest)
 (action (diff MatchGoal.expected MatchGoal.output)))

(rule
 (targets Module.output)
 (deps Module.v _dummy_target.v (package rocq-camltac))
 (action
  (with-stdout-to Module.output
   (system "mkdir -p .expected && rocq c -q -Q ../theories Camltac -R . Camltac.Tests -o .expected/Module.vo Module.v"))))

(rule
 (alias runtest)
 (action (diff Module.expected Module.output)))

(rule
 (targets Quasiquotes.output)
 (deps Quasiquotes.v _dummy_target.v (package rocq-camltac))
 (action
  (with-stdout-to Quasiquotes.output
   (system "mkdir -p .expected && rocq c -q -Q ../theories Camltac -R . Camltac.Tests -o .expected/Quasiquotes.vo Quasiquotes.v"))))

(rule
 (alias runtest)
 (action (diff Quasiquotes.expected Quasiquotes.output)))

(rule
 (targets Run.output)
 (deps Run.v _dummy_target.v (package rocq-camltac))
 (action
  (with-stdout-to Run.output
   (system "mkdir -p .expected && rocq c -q -Q ../theories Camltac -R . Camltac.Tests -o .expected/Run.vo Run.v"))))

(rule
 (alias runtest)
 (action (diff Run.expected Run.output)))
