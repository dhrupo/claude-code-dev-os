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
assert_contains "README warns that .dev-os-test runs on commit" "$(cat README.md)" "runs on every commit"
assert_contains "plan-check checks claims by command" "$(cat skills/plan-check/SKILL.md)" "command"
summary
