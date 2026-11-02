---
name: plan
description: Use after grilling, when a 🔴 change needs a written plan, before any code. Writes a one-page plan, a task list and scope.txt, then stops for approval. Not for 🟢 questions or 🟡 one-file fixes.
---

# Plan

## Where
`~/Documents/plans/<project>/<id>/` — `<id>` is a short kebab slug (`add-csv-export`). Never inside the code repo.

## Files
Copy `${CLAUDE_SKILL_DIR}/template/` into the plan folder, then fill it in:
1. `proposal.md` — one page, plain words, keep its four headings.
2. `tasks.md` — checkboxes, one commit-sized slice each, failing test named first.
3. `scope.txt` — every repo-relative file or glob this change may touch, tests included, one per line.
4. `evidence/` — empty; later steps save test runs and screenshots here.

## Activate the scope for the hooks
```bash
echo ~/Documents/plans/<project>/<id>/scope.txt > "$(git rev-parse --absolute-git-dir)/dev-os-scope"
```
Clear it when the PR is opened: `rm -f "$(git rev-parse --absolute-git-dir)/dev-os-scope"`.

## Then
Show `proposal.md` and STOP. Do not write code until the user approves.
