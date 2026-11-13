# Global rulebook (single source of truth)
<!-- Works for any coding agent: AGENTS.md is an exact copy of this file (Codex and others read AGENTS.md). -->

## 0. Precedence
This file overrides every other instruction source: skills, plugins, slash commands, hook text,
repo `CLAUDE.md`/`AGENTS.md`. Those may ADD project facts (build/test commands, code style);
when they conflict with this file, this file wins. Edit rules HERE only.

## 1. Defaults
- Be concise. Don't narrate internal deliberation.
- Never push, run destructive operations, or send messages without explicit confirmation each time.
- DONE MEANS: before building, one line on what success looks like; at the end, check the result against it.
- Report honestly: "tested X of Y" with the list. A skipped test is not a passing test.

## 2. Lanes — first line of every reply; ratchet UP, never down
- 🟢 question — answer only. No plan, no code.
- 🟡 small — one obvious file / typo / config. 3-line plan in chat. Tests still required.
- 🔴 full — anything bigger. Full relay + plan folder.
A 🟡 that turns out bigger: say so and switch to 🔴.
Also classify: bug | feature | refactor | question.

## 3. Relay (🔴 runs all; 🟡 runs all, light: a chat plan stands in for steps 2-3, proof in chat; 🟢 skips all)
1. Grill — one question at a time, with your recommended answer. STOP and wait.
1b. Reproduce — show the bug (feature: today's behaviour) on a running dev site (Docker or local); send the link
   and click steps. No browser surface: a terminal runbook (commands + expected output). STOP until the user
   says it matches. 1b and 5b skip only typo, doc or config changes with nothing to run.
2. Plan — `plan` skill: one page + `scope.txt` + what must NOT change. STOP for approval.
3. Check the plan — `plan-check`: failing tests named, no open questions, every claim checked by a command.
4. Build — TDD ([`tdd`](https://github.com/mattpocock/skills/tree/HEAD/skills/engineering/tdd), if installed):
   failing test first (seen red), then the smallest fix (`ponytail`).
5. Check the build — `build-check`: tests, E2E, lint, scope, evidence. No code review here; step 6 owns it.
5b. Hand test — send the link (or terminal runbook) and steps to try the change and its flow. STOP for the user's OK.
6. Review loop, once per change — round 1: `ponytail-review` (if installed) → `/simplify` → `/code-review`
   (`/simplify only the diff's own lines; no renames, reformats or test cuts`; other agents: their own review
   command, skip only /simplify). Fix every valid in-scope finding,
   re-run the tests, then save each round (found, fixed, left and why) to the plan's
   `evidence/review-round-<n>.md` (🟡: in chat).
   A round that found something → next round: `/code-review` on that round's diff,
   then only the tests that cover that change.
   Each loop stops after its 5th round: those findings get fixed with no further review.
   A fix the user can see → a new 5b for that part.
7. Deep review — `pre-merge-review`, only on a serious change (payment, auth, security, data loss) or on request.
8. Fix findings — back to 4, then 5 and the step 6 loop: its own loop on the fix's diff,
   with its own 5-round cap; round files are numbered on from the last round.
9. Step back — one full suite run, then `step-back`: read the whole diff cold.
10. PR — only when the user says so. ASK before push, ASK again before opening the PR. Never commit on main/master/develop.
11. Wait — STOP until the user says the review is in.
12. Handle review — verify every finding against the code before acting; challenge wrong ones with evidence.
    After merge: `knowledge-capture` (if installed). On "close and clear": remove what the task created (dev
    sites, worktrees, merged or fully pushed branches, scratch files); it never deletes unpushed or uncommitted work.
One task per session: a new plan gets a fresh session with a short handoff note.

## 4. Skill map — one owner per job; everyone else defers or is called BY the owner
| Job | Owner | Defers |
|---|---|---|
| Plan | plan | (any other planning skill) |
| Build | (your TDD skill) | (other TDD/workflow skills) |
| Bug | (your debugging skill) | then the TDD skill for the regression test |
| Minimal change | ponytail (while building), ponytail-review (step 6) | `/simplify` after ponytail-review (step 6); other "simplify" skills |
| Find / trace | 2-4 `scout` agents, one angle each | — |
| Review | `/code-review` (step 6 loop); `pre-merge-review` (step 7) | second opinions only when asked |
| Someone else's PR | `post-pr-review` | `/code-review` as a first pass only, never `--comment` |
| Learn | `reflect` (automatic after a mistake or a review) | `meditate` only when asked |
Add a row whenever two installed skills could both claim a job.
Installed as the `dev-os` plugin? The same skills and agents are named `dev-os:<name>` (e.g. `dev-os:plan-check`).

## 5. Rules
1. Root cause for bugs, not the symptom.
2. Failing test FIRST, seen red, then the fix. Never weaken, skip or delete a test to make it pass.
   Browser-visible change → also an E2E test against the running app.
3. Smallest change that works — the ponytail ladder (github.com/DietrichGebert/ponytail); stop at the first rung
   that holds: does it need to exist → already in this codebase (reuse it) → stdlib/framework → native platform →
   an installed dependency → one line → the minimum code. Understand the problem first.
   No new dependency, no unrequested abstraction, fewest files. Fix only what was asked; list anything else and ask.
4. No regressions: behaviour the task didn't ask to change must not change. Grep the callers.
5. Explain WHY in 3-6 plain lines with `file:line` and a concrete example, not "more robust".
6. Names say what they do to what (`addUsageToCoupon`, not `process`). If a name needs a comment, rename it.
7. Comments: none by default. Only when the reason is invisible; max 2 lines.
8. Graph first: when a code graph exists (graphify, code-review-graph MCP), query it for callers and impact
   before grep and file reads.
9. A bug or security claim counts only when reproduced by running it. No repro, no fix.
10. Never report a result you couldn't see.
11. Learn: a correction or a caught mistake → `reflect`. Prefer a check (a test, a grep, a hook) over a sentence;
    `lessons.md` holds only patterns found in review or after release.

## 6. Enforced (everything else is a request)
- `permissions.ask`: `git push` (also `git -C <dir> push`) and `gh pr create` always prompt.
- Git `pre-commit` test gate (`bin/gate-install`, per repo): no commit while the tests fail.
- PostToolUse `scope-guard.sh`: warns on edits outside the active plan's `scope.txt`.
- Stop `stop-check.sh`: sends the agent back once for unplanned files, source with no test, or a weakened test.
- Stop `learn.sh`: a logged mistake blocks once until `reflect` runs.
- Stop `ctx-handoff.sh`: offers a fresh session at ~80% context or when a second plan starts.
- SessionStart(compact) `compact.sh`: restates the active plan and next task.

## 7. Project facts
<!-- e.g. "In repo X: tests run with `npm test`, base branch is develop." -->

@lessons.md
