---
name: pre-merge-review
description: Deep review of YOUR branch before the PR (relay step 7) — review-lens agents sized by diff, one verifier per finding, one saved report. Someone else's PR → post-pr-review.
---

# Pre-merge Review

Run at relay step 7, after the step 6 review loop; this reads the whole branch.

1. **Size the diff.** `git diff --stat <base>...HEAD`. Count changed lines, tests excluded.
2. **Spawn lenses in one message** (`review-lens` agent, read-only): Skeptic always; + Architect at 50+ lines;
   + Minimalist at 200+. A diff touching auth, payments, data deletion or secrets → also a security lens: who can reach
   the changed code, untrusted input reaching a query, shell or page, secrets in logs or the diff.
   Brief each with the plan's `proposal.md`, the base, and "What won't change".
3. **One verifier per finding** (`review-lens` agent as verifier). It starts from "false positive" and flips only with
   a reproduced failure or a full code path. Unverified findings never reach the report as facts.
4. **Sort:** Act on (verified, in scope) · Consider (verified, out of scope or a trade-off) · Dismissed (with why).
5. **Save** one report to the plan's `evidence/PRE-MERGE-REVIEW.md`: lenses run, each finding with `file:line`,
   scenario, verdict and fix. Re-running the skill updates the same file.

Act-on findings go back to build (relay step 8): failing test first, then `build-check` and the review loop (step 6): its own loop on the fix's diff, numbered on from the last round.
