---
name: reflect
description: Use after a correction from the user, a hook catch (stop-check, test gate), a valid review finding, or a bug found after release. Turns what was missed into a check, a skill edit or a lesson. learn.sh asks for it automatically.
---

# Reflect — learn from what just happened

A correction or a finding means something was missed. Capture it now, without asking.

## 1. Collect
- Valid review findings (verified in the code, not challenged ones).
- A bug found after release: the root cause, and why no test or review caught it.
- A correction from the user, or a hook that blocked: what had to be said twice or fixed by hand.
- A multi-step job done by hand twice that no skill covers: propose a skill to the user (ask first).
Skip style nits and one-off facts.

## 2. Test each candidate
- **Durable?** "Would I put this in a prompt for a different task?" No → drop it.
- **Duplicate?** Grep `~/.claude/lessons.md`, `~/.claude/CLAUDE.md` and the owning skill. Already there → sharpen that line.

## 3. Route to the LOWEST layer that would have caught it
a. **A check** — a fixed pattern → a test, a grep in `build-check`, or a hook. A check beats a sentence.
b. **A skill edit** — one line in the owning skill's steps or gotchas.
c. **A lesson** — only for a review finding or a post-release bug: one line in `~/.claude/lessons.md`,
   the general pattern + `Check:` that catches it. No incident story.

## 4. Save and tell
Commit only the files you changed in `~/.claude` (`Lesson: <pattern>`). Tell the user one plain line per item and
where it lives (`file:line`). `lessons.md` over 60 lines → suggest running `meditate`.
