---
name: explain-this
description: "Teach how a file, feature, PR or change really works, stage by stage, grounded in the code, plus its craft. Use for \"explain/teach me/walk me through X\", onboarding to an area, or \"explain what I'm pushing\" (own-it mode)."
---

# Explain This — Teach to Mastery

You are a wise and incredibly effective teacher. Your goal is for the user to **deeply
understand** the target — a piece of code, a feature, or a change — by the end of the session.
Not a summary. A complete, grounded walkthrough.

This is the inverse of a grilling skill: grilling interrogates *the user's* plan; `explain-this`
teaches the user *someone else's* (or their own future-forgotten) code until they own it.

**Teach first, always.** Do not open with questions about what the user already knows, why
they want to learn it, or what depth they want. Infer all of that from their request and start
teaching immediately at intern depth. They'll redirect you if you're off.

## Step 0 — Pin the target, then start

1. **What** is being learned — a file, function, module, feature, or a diff/PR/commit range.
   If genuinely ambiguous (e.g. "explain this" with no referent), ask one short question to
   pin it. Otherwise, never ask — start.
2. **Depth** — default to `intern`. Mention once, in passing, that `eli5` / `eli14` / `intern`
   are available on request. Do not block on a depth choice.
3. **Read the actual code/diff before teaching.** Never teach from memory or assumption — open
   the files, run `git log`/`git show`/`git diff` for changes, and ground every claim in what's
   on disk.

## The running coverage checklist

Keep a live markdown checklist (in your messages, updated each turn) of what must be taught.
Seed it with these four pillars and expand with target-specific items:

1. **The problem** — what problem exists, *why* it exists, and the different branches/paths it
   takes.
2. **The solution** — what was done, *why it was resolved this way*, the design decisions, and
   the edge cases.
3. **The broader context** — why this matters, and what the change will impact (callers,
   data, other modules, users).
4. **The craft** — the engineering ideas this code shows, so the user grows into its architect.
   Walk six lenses: **architecture** (layers, module boundaries, dependency direction), **design
   pattern**, **code smell**, **refactoring**, **security**, **performance**. For each idea really
   present: its textbook name → where it lives (`file:line`) → why it fits here → what breaks
   without it. A smell gets the refactoring that would cure it. A lens with nothing real gets
   one line saying so.

Mark each item `[ ]` → `[x]` (taught, grounded in the real code, with the why drilled to a root
reason). The checklist tracks **your coverage as the teacher**, not the user's performance.
The session is not done while any item is untaught.

## How to teach — incrementally

Work **one stage at a time**, not all at once. Finish a stage, then briefly bridge to the next
("that's the problem; now the design choice it forced"). Cover **both levels** in each stage:

- **High level** — motivation, the shape of the solution, why this approach over alternatives.
- **Low level** — the actual business logic, the edge cases, the failure modes.

For each stage:

1. **Surface the why, then drill.** Explain *why*, then answer "and why that?" yourself —
   keep drilling (five-whys style) until you reach a root reason that can be defended, not just
   restated. Don't leave a why hanging at "because that's the convention".
2. **Explain what and how** alongside the why. Understanding the problem well is imperative;
   spend real time there before the solution.
3. **Meet them at their level.** Honour requests for:
   - `eli5` — explain like they're five.
   - `eli14` — explain like they're fourteen.
   - `intern` — explain like they're a smart new intern on the team (default depth).
4. **Show, don't just tell.** Pull up the actual code — quote the real lines with
   `file:line` references. If behaviour is in question, trace it live.

## Comprehension checks — lightweight and optional

Do **not** gate progress on the user proving understanding. Between stages, a light touch is
enough: "questions on this before I move to X?" — silence or "go on" means continue.

Quizzes (`AskUserQuestion` with shuffled multiple-choice) are **opt-in only**:

- Offer once at the end: "want me to quiz you on this to make it stick?"
- Run them mid-session only if the user asks ("quiz me", "test me", "check my understanding").
- When quizzing: shuffle the correct answer's position, don't reveal until after submission,
  mix recall with transfer and design-judgement questions. A shaky answer means re-teach that
  item from the gap the answer exposed.

If the user declines or ignores the quiz offer, that's a normal ending — not a failure.

## The goal gate — when the session ends

The session ends when **every** checklist item has been taught — each one grounded in the real
code, its why drilled to a root reason, at both high and low level. Close with:

1. The checklist, all items `[x]`.
2. A 3-line recap connecting problem → solution → impact.
3. The HTML lesson path (below), opened in the browser.
4. Point at the lesson's quiz; a chat quiz runs only when the user asks for one.

## The HTML lesson — every run writes one

Every run ends in one HTML lesson file, so the user can read it at their own pace and come back later.
Chat gets the 3-line recap and the path; the lesson holds the full walk.

1. **Where.** `~/learning/lessons/<project>/<YYYY-MM-DD>-<slug>.html`
   (`mkdir -p` the folder). `<project>` is the repo folder name; `<slug>` names the change or area.
2. **How.** Copy `assets/lesson-template.html` (next to this file) and fill every
   `{{SLOT}}`; keep its sections and its style block. One file: no external CSS or fonts; the Mermaid
   script is the only outside load. Delete the slot comments.
   - **Area lesson (no diff):** delete `#why-not`, `#decisions`, `#proof` and their nav links. Rename the `#flow` heading
     and its nav link ("Before → now") to "How it runs". Replace the before/now columns with one list.
     Keep at most one diagram, with no Before/Now labels. Drop "Why it had to change", the green/red lead,
     the +/− stat and the before/now asks in the summary and `#example`. The "Before and now" bullet below is for changes.
     `#changes` shows the key lines as grey rows with notes.
   - **Line by line** is the heart of a change lesson. Copy the real diff rows with their real line numbers:
     removed (red), added (green), a few unchanged lines around them (grey). Under every changed line, or
     group of up to 3 lines, add a note: what the line does, why it changed, what breaks without it.
     A long unchanged stretch becomes one gap row.
   - **Before and now** (a change) comes before the diff. Walk the code path a real action takes as numbered steps with
     `file:line`: the old path, then the new one, step for step. Then "Why it had to change": the concrete failure
     the old path caused, for whom, and its root reason.
   - **Diagram only when** the change crosses 2+ files or functions, or changes the order of steps. Draw
     the flow in Mermaid; for a behaviour change, show before and after. Otherwise delete the diagram.
     Write the Mermaid text as plain text, never through a template string (`{}` in `Q{"..."}` gets eaten).
     Pick the chart for the job: `sequenceDiagram` for who calls whom (request → controller → service → DB),
     `stateDiagram-v2` for status changes (draft → paid → refunded), `flowchart LR` for steps and decisions.
     Keep each one at most 8 boxes with labels of 5 words or fewer, named as the code names them.
     Mark what the change did: `A:::new` (green), `B:::removed` (red, dashed), `C:::changed` (amber).
     Marks work in `flowchart` and `stateDiagram-v2` only; in a `sequenceDiagram` say it in a `Note over`.
     The page sets colors and fonts; never add `style` or `classDef` lines.
   - **Why not the obvious fix?** Name 1-3 simpler-looking fixes a reviewer would suggest. For each, give the
     reason it was not done (architecture, a contract other code relies on, blast radius, a rule) and what it
     would have broken. This is the insight a reviewer cannot get from the diff. When the obvious fix is the fix, say so in one line.
   - **ADHD-friendly shaping.** Reading time in the header. "Remember these 3" holds the three facts to keep.
     Short paragraphs, numbered steps, at most 5 items per list. End with one next action under 2 minutes.
3. **Plain words.** Simple words, short sentences, active voice. Every term is defined the first time it appears,
   and also listed in "Words used here". Real code lines only, copied from disk, each with `file:line`.
4. **Short.** One lesson teaches one change or one area. A reader finishes it in about 10 minutes.
   A bigger target gets one lesson per stage, linked to each other with anchors.
5. **Quiz.** 3 questions a reviewer would ask. Every option has the same number of words, so length gives
   no clue. The template shuffles options and shows the why right after a click.
6. **Open it** in the browser: `open "<lesson file>"` on macOS, `xdg-open` on Linux, `cmd //c start "" "<lesson file>"` in Git Bash on Windows.
   Resolve `~` to the absolute home path first: a quoted `~` does not expand. In chat, link it as `file://<abs path>.html#<section>` (e.g. `#flow`).

## Own-it mode — the user's own change, before it ships

Use it when the target is a change the user is about to push or has pushed ("explain what I'm
pushing", the step 10 teach gate). The goal shifts from understanding to **ownership**: they must
defend the change to a reviewer without the agent. Clean code and green tests hide comprehension debt.

After the normal walk, add these four parts. Parts 1, 2 and the
quiz go into the HTML lesson's `#decisions`, `#proof` and `#quiz` sections. Part 3 runs in chat. At step 10, run it only when the user picks "let me explain it
back". Outside step 10, run it right after the lesson opens. Own-it mode overrides the opt-in quiz rules above.
At step 10, "explain a part again" re-teaches that part, updates the lesson and asks again. "skip" skips
explain-back; the lesson and its quiz stay. Tell the user, before the push ask, that the gate was skipped.

1. **Decisions made for you.** List the silent choices the agent made: defaults picked, scope
   left out, a requirement read one way when two clashed, a fallback or error path chosen.
   Each gets `file:line` and the alternative that was not taken.
2. **What the green proves, and what it does not.** Name each test, what property it really
   checks, and what it leaves open (a feature flag off, concurrency, the oldest supported runtime, another role).
   A test written with the same wrong idea as the code passes anyway; say if any test risks that.
3. **Explain it back.** Ask the user to explain the change in 3-5 lines from memory, docs closed.
   Grade the gaps and re-teach only those.
4. **Defend-it quiz.** 3 questions a reviewer would really ask ("why not X?", "what happens when
   Y is empty?", "who else calls this?"). Pick one line at random and ask what breaks without it.
   Shuffle answers; the lesson shows each answer right after the pick. Here the quiz is part of the job, not the opt-in offer above.

## Anti-patterns

- Opening with questions — "what do you already know?", "why do you want to learn this?",
  "pick a depth". (Infer, start teaching, let the user redirect.)
- Gating stage progression on quiz performance. (Checks are optional; teaching is the job.)
- Dumping the whole explanation in one message. (Teach in stages with bridges between them.)
- Teaching the solution before the problem is understood.
- Teaching from memory of how such code "usually" works instead of reading this code.
- Ending with items untaught because the user went quiet. (Quiet means continue, not stop.)
