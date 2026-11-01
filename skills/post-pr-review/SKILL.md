---
name: post-pr-review
description: Review someone else's open PR — find regressions, prove each finding by running it, draft human replies. Use for "review this PR" on a PR you did not write. Your own branch → pre-merge-review.
---

# Post-PR Review

Read-only on code. Never push to the author's branch, never edit their files.

1. **Collect.** `gh pr view <n>`, `gh pr diff <n>`, and every earlier review and comment, so no point is repeated.
2. **Review through these lenses** (`review-lens` agents for a big PR, one lens each):
   - Regression: grep every caller of each changed function, key or event; walk every use case the change touches.
   - Workarounds: what users already did to live with the old behaviour, and what this PR does to them.
   - Reuse: new code where a helper already exists (`file:line`).
   - Siblings: the same bug left elsewhere.
   - Minimal change: what can be deleted, bundled refactors hiding the real change.
3. **Verify.** One verifier per finding, starting from "false positive". Re-check every High yourself in the code.
4. **Prove by running.** Each finding runs on the base branch and on the PR branch (test, script or browser) in a
   temp checkout. Not reproduced → cut it. Can't run it → label it "from the code, not run".
5. **Draft** one review per PR in plain, human words: what breaks, the input that shows it, the smallest fix.
   Request changes only for a proven regression or data loss; everything else is a comment.
6. **Ask the user before posting.** Then post with `gh pr review <n> --comment|--request-changes --body-file <draft>`
   and confirm it landed.
