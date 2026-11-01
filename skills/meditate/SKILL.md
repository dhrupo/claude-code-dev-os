---
name: meditate
description: Use only when the user asks (or lessons.md passes its line budget). Audits CLAUDE.md, lessons.md and skills for stale, duplicate, contradicting or verbose rules and proposes cuts.
---

# Meditate — tidy what we have learned

Keep the pages you still use, merge the repeats, throw out what no longer applies.

1. Read `~/.claude/CLAUDE.md`, `~/.claude/lessons.md`, the skill descriptions, and `~/.claude/state/skill-usage.jsonl`
   (with 30+ days of log, a skill never used is a candidate to retire: ask, never delete).
2. Spawn 2 agents in parallel: A audits rules + lessons, B audits skills. Each flags:
   - **stale** — names a file, function or flag that no longer exists (verify by grep),
   - **duplicate** — the same rule in 2+ places (keep one owner, point to it elsewhere),
   - **contradicting** — two rules disagree,
   - **verbose** — can be said in half the words,
   - **demotable** — a lesson that a test, grep or hook could check instead.
   Before flagging, grep `~/.claude/tests/` for the text: a test that pins it means it is on purpose.
3. Fewer than 3 findings → say "nothing worth tidying" and stop.
4. Show one table: item → finding → proposed change → evidence.
5. ASK before any deletion or merge. Apply only what is approved, commit, and re-run the tests.
