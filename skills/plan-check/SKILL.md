---
name: plan-check
description: Use right after the plan is written and before any code. Gates the PLAN, not the code. If a check fails, fix the plan.
---

# Plan Check

1. **Tests named.** The plan names the exact failing test(s) to write first. No named test = fail.
2. **Must-not-change listed.** "What won't change" names the behaviour at risk and how the diff avoids it. Grep the callers if unsure.
3. **Smallest change.** No new dependency, no new public API, no new class for a bug fix, fewest files.
4. **No open questions.** Every question from grilling is answered or explicitly deferred in writing.

One line per check, pass/fail. All pass → build. Any fail → fix the plan and re-run.
