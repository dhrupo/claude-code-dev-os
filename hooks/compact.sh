#!/bin/bash
# SessionStart(compact): restate the active plan and its next unticked task, which compaction tends to drop.
CWD=$(jq -r '.cwd // empty' 2>/dev/null)
[ -d "$CWD" ] || exit 0
GITDIR=$(git -C "$CWD" rev-parse --absolute-git-dir 2>/dev/null) || exit 0
SCOPE=$(cat "$GITDIR/dev-os-scope" 2>/dev/null) || exit 0
PLAN=$(dirname "$SCOPE")
NEXT=$(grep -m1 -E '^- \[ \]' "$PLAN/tasks.md" 2>/dev/null | sed -E 's/^- \[ \] *//')
[ -n "$NEXT" ] || exit 0
echo "Active plan after compaction: $PLAN. Next unticked task: $NEXT. Re-read proposal.md and tasks.md before continuing."
