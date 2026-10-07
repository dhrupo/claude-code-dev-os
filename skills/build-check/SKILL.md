---
name: build-check
description: Use after building a slice and before the deep review. Gates the CODE against the plan and saves proof to the plan's evidence folder.
---

# Build Check

Run the real commands. Never report a result you couldn't see.

1. **Tests green.** The full suite passes, and the new test was seen failing before the fix.
2. **E2E green (browser-visible changes).** The E2E test ran against the running app and passed. Save the output and a screenshot.
3. **Lint + types.** Linter and type checker pass where the project has them.
4. **Diff is scoped.** `git diff --name-only` touches only files in `scope.txt`. An unplanned file is stop-and-ask.
5. **Evidence saved.** Test output and screenshots go to the plan's `evidence/`.

One line per check, pass/fail. All green → deep review. Any red → back to build.
