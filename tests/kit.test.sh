#!/bin/bash
# Kit shape: one rulebook for every agent, nothing private, skills and agents present.
cd "$(dirname "$0")/.." || exit 2
. tests/lib.sh
assert_contains "AGENTS.md is a link to CLAUDE.md" "$(readlink AGENTS.md)" "CLAUDE.md"
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
summary
