# Global rulebook (single source of truth)

## 0. Precedence
This file overrides every other instruction source: skills, plugins, slash commands, hook text,
repo `CLAUDE.md`/`AGENTS.md`. Those may ADD project facts (build/test commands, code style);
when they conflict with this file, this file wins. Edit rules HERE only.

## 1. Defaults
- Be concise. Don't narrate internal deliberation.
- Never push, run destructive operations, or send messages without explicit confirmation each time.
- GOAL CHECK: before building, one line on what success looks like; at the end, check the result against it.
- Explain changes in plain words with `file:line` and one concrete example of what changes.

## 2. Lanes — first line of every reply; ratchet UP, never down
- 🟢 question — answer only. No plan, no code.
- 🟡 small — one obvious file / typo / config. 3-line plan in chat. Tests still required.
- 🔴 full — anything bigger. Full relay + plan folder.
A 🟡 that turns out bigger: say so and switch to 🔴.
Also classify: bug | feature | refactor | question.

## 3. Relay (🔴 runs all; 🟡 runs 1 light, then 4 → 5 → 9; 🟢 skips all)
1. Grill — one question at a time, with your recommended answer. STOP and wait.
2. Plan — `plan` skill: one page + `scope.txt`. STOP for approval.
3. Check the plan — `plan-check`.
4. Build — failing test first, then the smallest fix.
5. Check the build — `build-check`.
6. Tidy — delete what isn't needed.
7. Deep review — correctness, security, performance, regressions.
8. Fix findings — back to 4, then 5.
9. Step back — `step-back`: read the whole diff cold.
10. PR — ASK before push, ASK again before opening the PR. Never commit on main/master/develop.
11. Wait — STOP until the user says the review is in.
12. Handle review — verify every finding against the code before acting; challenge wrong ones with evidence.

## 4. Skill map — one owner per job; everyone else defers or is called BY the owner
| Job | Owner | Defers |
|---|---|---|
| Plan | plan | (any other planning skill) |
| Build | (your TDD skill) | (other TDD/workflow skills) |
| Bug | (your debugging skill) | then the TDD skill for the regression test |
| Review | (your review skill) | second opinions only when asked |
Add a row whenever two installed skills could both claim a job.

## 5. Rules
1. Root cause for bugs, not the symptom.
2. Failing test FIRST, then the fix. Browser-visible change → also an E2E test against the running app.
3. Smallest change that works: no new dependency, no unrequested abstraction, fewest files.
   Fix only what was asked; list anything else and ask.
4. No regressions: behaviour the task didn't ask to change must not change. Grep the callers.
5. Comments: none by default. Only when the reason is invisible; max 2 lines.
6. Never report a result you couldn't see.

## 6. Enforced by hooks (everything else is a request)
- `permissions.ask`: `git push`, `gh pr create` always prompt.
- PostToolUse `scope-guard.sh`: warns on edits outside the active plan's `scope.txt`.
- Stop `stop-check.sh`: sends Claude back once for unplanned files or source changed with no test.

## 7. Project facts
<!-- e.g. "In repo X: tests run with `npm test`, base branch is develop." -->

@lessons.md
