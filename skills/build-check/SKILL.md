---
name: build-check
description: Use after building a slice and before the hand test (relay 5b) and the step 6 review loop. Gates the CODE against the plan and saves proof to the plan's evidence folder.
---

# Build Check

Run the real commands. Never report a result you couldn't see.

1. **Tests green.** The full suite passes, and the new test was seen failing before the fix.
2. **E2E green (browser-visible changes).** The E2E test ran against the running app and passed. Save the output and a screenshot.
3. **Lint + types.** Linter and type checker pass where the project has them.
4. **Diff is scoped.** `git diff --name-only` touches only files in `scope.txt` (🟡: the chat plan). An unplanned file is stop-and-ask.
5. **No code review here.** The relay step 6 loop runs it once per change, after the hand test.
6. **Evidence saved.** Test output and screenshots go to the plan's `evidence/` (🟡: in chat).

One line per check, pass/fail. All green → next slice; after the last slice, hand test (relay 5b; on a step 8
fix, only if the user can see it), then the step 6 review loop. Any red → back to build.
