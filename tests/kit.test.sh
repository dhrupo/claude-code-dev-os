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
LEAK=$(grep -rIlE '/Users/|/Volumes/|/home/[a-z]' --exclude-dir=.git --exclude=kit.test.sh . )
assert_contains "no absolute home paths (got: $LEAK)" "[$LEAK]" "[]"
if [ -s tests/.private-patterns ]; then
  PRIV=$(grep -rIlf tests/.private-patterns --exclude-dir=.git --exclude=.private-patterns . )
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
assert_contains "build-check runs /code-review" "$(cat skills/build-check/SKILL.md)" "/code-review"
assert_contains "relay step 5 names /code-review" "$(grep '^5\. ' CLAUDE.md)" "/code-review"
assert_contains "relay step 7 names pre-merge-review" "$(grep '^7\. ' CLAUDE.md)" "pre-merge-review"
assert_contains "skill map routes others' PRs to post-pr-review" "$(grep '^|' CLAUDE.md)" "post-pr-review"
assert_contains "build-check has a fallback without /code-review" "$(cat skills/build-check/SKILL.md)" "other agents:"
assert_contains "relay step 5 has a fallback without /code-review" "$(grep -A1 '^5\. Check the build' CLAUDE.md)" "other agents:"
assert_contains "relay step 6 names /simplify" "$(grep -A2 '^6\. Tidy' CLAUDE.md)" "/simplify"
assert_contains "relay step 6 has a fallback without /simplify" "$(grep -A2 '^6\. Tidy' CLAUDE.md)" "other agents:"
assert_contains "relay step 6 re-runs the tests after /simplify" "$(grep -A2 '^6\. Tidy' CLAUDE.md)" "re-run the tests"
assert_contains "relay step 6 keeps /simplify off tests and names" "$(grep -A2 '^6\. Tidy' CLAUDE.md)" "no renames, reformats or test cuts"
assert_contains "pre-merge-review sends fixes through the tidy step too" "$(cat skills/pre-merge-review/SKILL.md)" "tidy step (6)"
assert_contains "fixes after review get the tidy pass too" "$(grep '^8\. ' CLAUDE.md)" "then 5 and 6"
assert_contains "skill map row runs /simplify at the tidy step" "$(grep '^| Minimal change' CLAUDE.md)" "/simplify"
assert_not_contains "relay step 7 leaves lens sizes to pre-merge-review" "$(sed -n '/^7\. Deep review/,/^8\. /p' CLAUDE.md)" "200+"
assert_contains "pre-merge-review defines its security lens" "$(cat skills/pre-merge-review/SKILL.md)" "who can reach"
assert_contains "post-pr-review row defers /code-review --comment" "$(grep "^| Someone else's PR" CLAUDE.md)" "never \`--comment\`"
assert_contains "post-pr-review reads inline review comments" "$(cat skills/post-pr-review/SKILL.md)" "pulls/<n>/comments"
summary
