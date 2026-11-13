#!/bin/bash
# Kit shape: one rulebook for every agent, nothing private, skills and agents present.
cd "$(dirname "$0")/.." || exit 2
. tests/lib.sh
assert_contains "AGENTS.md is an exact copy of CLAUDE.md" "$(cmp -s AGENTS.md CLAUDE.md && echo same)" "same"
assert_contains "the repo tracks no symlinks (the plugin directory blocks them)" "[$(git ls-files -s 2>/dev/null | awk '$1==120000 {print $4}'; echo "${PIPESTATUS[0]}")]" "[0]"
assert_contains "graph first rule" "$(cat CLAUDE.md)" "graph"
assert_contains "smallest-change ladder credits ponytail" "$(cat CLAUDE.md)" "github.com/DietrichGebert/ponytail"
assert_contains "ladder has the reuse rung" "$(cat CLAUDE.md)" "already in this codebase"
assert_contains "rulebook routes learning to reflect" "$(cat CLAUDE.md)" "reflect"
for f in skills/reflect/SKILL.md skills/meditate/SKILL.md agents/review-lens.md agents/scout.md bin/gate-install; do
  assert_contains "$f present" "$(test -s "$f" && echo yes)" "yes"
done
assert_contains "lessons.md has a line budget" "$(cat lessons.md)" "60 lines"
# In a git worktree .git is a file holding an absolute path, so it needs --exclude as well as --exclude-dir.
LEAK=$(grep -rIlE '/Users/|/Volumes/|/home/[a-z]' --exclude-dir=.git --exclude=.git --exclude=kit.test.sh . )
assert_contains "no absolute home paths (got: $LEAK)" "[$LEAK]" "[]"
if [ -s tests/.private-patterns ]; then
  PRIV=$(grep -rIlf tests/.private-patterns --exclude-dir=.git --exclude=.git --exclude=.private-patterns . )
  assert_contains "no private names (got: $PRIV)" "[$PRIV]" "[]"
fi
assert_contains "private pattern list is never committed" "$(cat .gitignore 2>/dev/null)" "tests/.private-patterns"
assert_contains "plan skill ships its template" "$(test -s skills/plan/template/proposal.md && echo yes)" "yes"
assert_contains "plan skill copies its template" "$(cat skills/plan/SKILL.md)" "template/"
assert_contains "upgrade replaces the v1 plan skill" "$(cat README.md)" 'cp "$KIT/skills/plan/SKILL.md" ~/.claude/skills/plan/'
assert_contains "upgrade replaces the v1 plan-check skill" "$(cat README.md)" 'cp "$KIT/skills/plan-check/SKILL.md" ~/.claude/skills/plan-check/'
assert_contains "upgrade replaces the v1 build-check skill" "$(cat README.md)" 'cp "$KIT/skills/build-check/SKILL.md" ~/.claude/skills/build-check/'
assert_contains "README lists the review skills" "$(grep '^|' README.md)" "pre-merge-review"
assert_contains "README warns that .dev-os-test runs on commit" "$(cat README.md)" "runs on every commit"
assert_contains "plan-check checks claims by command" "$(cat skills/plan-check/SKILL.md)" "command"
for f in skills/pre-merge-review/SKILL.md skills/post-pr-review/SKILL.md; do
  assert_contains "$f present" "$(test -s "$f" && echo yes)" "yes"
  assert_contains "$f is generic (got: $(grep -ioE 'wordpress|wp-|php' "$f" 2>/dev/null | head -1))" "[$(grep -ilE 'wordpress|wp-|php' "$f" 2>/dev/null)]" "[]"
done
PMR=$(cat skills/pre-merge-review/SKILL.md 2>/dev/null)
assert_contains "pre-merge-review uses review-lens agents" "$PMR" "review-lens"
assert_contains "pre-merge-review verifies each finding" "$PMR" "verifier"
assert_contains "pre-merge-review saves its report to evidence/" "$PMR" "evidence/"
PPR=$(cat skills/post-pr-review/SKILL.md 2>/dev/null)
assert_contains "post-pr-review asks before posting" "$PPR" "Ask the user before posting"
assert_contains "post-pr-review never pushes to the author's branch" "$PPR" "Never push to the author's branch"
RELAY=$(sed -n '/^## 3\. Relay/,/^## 4\. /p' CLAUDE.md)
relay_step() { printf '%s\n' "$RELAY" | grep -A"${2:-0}" "^$1\. "; }
lc() { tr '[:upper:]' '[:lower:]'; }
assert_not_contains "build-check leaves /code-review to the step 6 loop" "$(lc < skills/build-check/SKILL.md)" "/code-review"
assert_contains "build-check skips 5b for an unseen step 8 fix" "$(cat skills/build-check/SKILL.md)" "only if the user can see it"
assert_contains "build-check scope check has a 🟡 fallback" "$(cat skills/build-check/SKILL.md)" "🟡: the chat plan"
assert_contains "build-check evidence has a 🟡 fallback" "$(cat skills/build-check/SKILL.md)" "🟡: in chat"
assert_contains "pre-merge-review fix gets its own step 6 loop" "$(cat skills/pre-merge-review/SKILL.md)" "own loop on the fix's diff"
assert_contains "build-check sends only the last slice to the hand test" "$(cat skills/build-check/SKILL.md)" "after the last slice"
assert_not_contains "relay step 5 has no /code-review" "$(relay_step 5 1 | lc)" "/code-review"
assert_contains "relay step 7 names pre-merge-review" "$(relay_step 7)" "pre-merge-review"
assert_contains "skill map routes others' PRs to post-pr-review" "$(grep '^|' CLAUDE.md)" "post-pr-review"
CM=$(cat CLAUDE.md)
S6=$(sed -n '/^6\. Review loop/,/^7\. /p' CLAUDE.md)
assert_contains "relay step 6 chain order, ponytail-review optional" "$S6" "\`ponytail-review\` (if installed) → \`/simplify\` → \`/code-review\`"
assert_contains "relay step 6 saves each round to evidence/" "$S6" "save each round (found, fixed, left and why)"
assert_contains "relay step 6 🟡 log goes in chat" "$S6" "evidence/review-round-<n>.md\` (🟡: in chat)"
assert_contains "relay step 6 has a fallback for other agents" "$S6" "other agents:"
assert_contains "relay step 6 re-runs the tests" "$S6" "re-run the tests"
assert_contains "relay step 6 keeps /simplify off tests and names" "$S6" "no renames, reformats or test cuts"
assert_contains "relay step 6 later rounds test only the change" "$S6" "only the tests that cover that change"
assert_contains "relay step 6 caps the loop at 5 rounds" "$S6" "Round 5 findings get fixed with no 6th review"
assert_contains "1b: reproduce and wait for the user" "$CM" "1b. Reproduce"
assert_contains "5b: hand test and wait for the user" "$CM" "5b. Hand test"
assert_contains "hand tests fall back to a terminal runbook" "$CM" "terminal runbook"
assert_contains "relay step 7 runs only on serious changes or on request" "$(relay_step 7)" "only on a serious change"
assert_contains "relay step 9 runs one full suite first" "$(relay_step 9)" "one full suite"
assert_contains "relay step 12 names knowledge-capture" "$(relay_step 12 1 | lc)" "knowledge-capture"
assert_contains "close and clear keeps unpushed work" "$CM" "never deletes unpushed or uncommitted work"
assert_contains "pre-merge-review sends fixes through the step 6 loop" "$(cat skills/pre-merge-review/SKILL.md)" "review loop (step 6)"
assert_contains "fixes after review go through the step 6 loop" "$(relay_step 8)" "then 5 and the step 6 loop"
assert_contains "skill map row runs /simplify in step 6" "$(grep '^| Minimal change' CLAUDE.md)" "/simplify"
assert_not_contains "skill map has no tidy step left" "$(grep '^|' CLAUDE.md | lc)" "tidy"
assert_contains "skill map Review row names /code-review" "$(grep '^| Review' CLAUDE.md)" "/code-review"
assert_not_contains "relay step 5 claims no test-quality check" "$(relay_step 5 1 | lc)" "test quality"
assert_contains "relay step 5 names E2E and evidence" "$(relay_step 5)" "E2E, lint, scope, evidence"
assert_contains "relay step 8 fix gets its own loop" "$(relay_step 8)" "own loop on the fix's diff"
assert_contains "relay step 8 loop never overwrites round files" "$(relay_step 8 1)" "numbered on from the last round"
assert_not_contains "relay step 8 numbering works without round files (🟡)" "$(relay_step 8 1)" "last round file"
assert_contains "pre-merge-review fix loop numbers on" "$(cat skills/pre-merge-review/SKILL.md)" "numbered on from the last round"
assert_contains "relay step 6 saves the round after the test re-run" "$S6" "re-run the tests, then save each round"
assert_contains "🟡 chat plan stands in for steps 2-3" "$(grep '^## 3\. Relay' CLAUDE.md)" "steps 2-3"
U22=$(sed -n '/^## Upgrading to 2.2.0/,/^## /p' README.md)
assert_contains "2.2.0 upgrade re-syncs AGENTS.md" "$U22" "AGENTS.md"
assert_not_contains "2.2.0 upgrade copies no hooks (2.2.0 changes none)" "$U22" "/hooks/"
assert_contains "2.2.0 upgrade says why pre-merge-review and step-back change" "$U22" "old tidy step"
for f in build-check pre-merge-review step-back; do
  assert_contains "2.2.0 upgrade replaces $f" "$U22" "cp \"\$KIT/skills/$f/SKILL.md\""
done
assert_not_contains "relay step 7 leaves lens sizes to pre-merge-review" "$(sed -n '/^7\. Deep review/,/^8\. /p' CLAUDE.md)" "200+"
assert_contains "pre-merge-review defines its security lens" "$(cat skills/pre-merge-review/SKILL.md)" "who can reach"
assert_contains "post-pr-review row defers /code-review --comment" "$(grep "^| Someone else's PR" CLAUDE.md)" "never \`--comment\`"
assert_contains "post-pr-review reads inline review comments" "$(cat skills/post-pr-review/SKILL.md)" "pulls/<n>/comments"
summary
