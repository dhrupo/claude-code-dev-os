---
name: step-back
description: Use after the deep review and fixes, before opening a PR. Re-read the whole diff cold, as if a stranger wrote it, then give a plain-words summary.
---

# Step Back

1. `git diff <base>...HEAD` — read the ENTIRE diff top to bottom as if a stranger wrote it.
2. Ask honestly: **would I approve this?** Anything surprising, half-finished, or wider than the plan?
3. Re-check the plan's "What won't change" against the real diff.
4. If something is off, say so and go back to build. Don't rationalise it away.

Then summarise in 3–6 lines: a real-life comparison first, what changed with `file:line`, and what you deliberately did NOT do and why.
