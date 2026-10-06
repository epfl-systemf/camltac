Pattern matching
================

.. _pattern-matching-over-terms:

Pattern matching over terms
---------------------------

.. cmd:: match%%@match-key @term-scrutinee with {+ @term-case }
   :name: match-term

   .. prodn::
      match-key ::= rocq
      | lazy
      | multi
      term-scrutinee ::= @ocaml-expr
      | @string
      | @constr-quotation
      term-case ::= %| @term-pattern -> @ocaml-expr
      term-pattern ::= @pattern
      | Context @pattern {? as @ident }
      pattern ::= %{| @cpattern |%}
      | _

   Matches the term :token:`term-scrutinee`, of type :ltac2-type:`constr`, against any of the :token:`term-case` in order.

   In a branch, a pattern variable `?x` is bound to an OCaml variable named `x` of type :ltac2-type:`constr`. When a match is found, `x` contains the value of the matched variable `?x`.

   If a branch fails, matching may continue with later branches depending on :token:`match-key`.

   As in Ltac, matching is non-linear, i.e., pattern variables that occur more than once must be syntactically equal or be `α-convertible <https://rocq-prover.org/doc/master/refman/language/core/conversion.html#term-alpha-convertible>`_.

   .. attr:: match%%lazy

      Non-backtracking match: if a branch fails, the match is exited. In other words, `match%lazy` commits to the first matching branch.

   .. attr:: match%%rocq

      Backtracking match: if a branch fails, the next branch is tried.

   .. attr:: match%%multi

      Multi-success match: behaves like `match%rocq`, except that a failure after the match also backtracks to the next branch.

   .. attr:: Context @pattern {? as @ident }
      :name: Context

      Matches a subterm instead of the whole term (equivalent to Ltac's `context ident [ pattern ]`). If :token:`ident` is specified, the context is bound to an OCaml variable of the same name in the branch.

.. _pattern-matching-over-goals:

Pattern matching over goals
---------------------------

.. cmd:: match%%@match-key {? reverse } goal with {+ @goal-case }
   :name: match-goal

   .. prodn::
      goal-case ::= %| @goal-pattern -> @ocaml-expr
      goal-pattern ::= @hypotheses-pattern , @term-pattern
      hypotheses-pattern ::= %{ {*; @hypothesis-pattern } %}
      | _
      hypothesis-pattern ::= @ident = @term-pattern
      | @ident = @term-pattern :: @term-pattern

   Matches the current goal against any of the :token:`goal-pattern`.

   .. attr:: {? reverse}
      :name: reverse

      If `reverse` is specified, hypotheses are matched in the reverse order.

   .. attr:: @goal-pattern
      :name: goal-pattern

      Specifies how to match the goal's hypotheses and conclusion.

   .. attr:: @hypothesis-pattern
      :name: hypothesis-pattern

      Matches a single hypothesis.

      .. attr:: @ident = @term-pattern
         :name: hypothesis-pattern-body

         Matches the body of the hypothesis against :token:`term-pattern`. If :token:`term-pattern` is `_`, matching succeeds regardless of whether the hypothesis has a body or not.

         .. warning::

            Do not confuse `_` with `{|_|}`: the former matches any hypothesis, while the latter matches only if the hypothesis has a body (regardless of the body).

      .. attr:: @ident = @term-pattern :: @term-pattern
         :name: hypothesis-pattern-body-type

         Matches the body and type of the hypothesis against :token:`term-pattern`.
