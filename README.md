# claude-code-dev-os

A small starter kit for a calmer Claude Code setup: one rulebook, a relay of named steps,
and three hooks that enforce the parts that matter. Companion to the post
**"How I set up Claude Code for daily use"**.

## What's inside

| Path | What it does |
|---|---|
| `CLAUDE.md` | Rulebook template: precedence, lanes 🟢🟡🔴, 12-step relay, skill map, rules |
| `lessons.md` | One line per review finding you should have caught (imported by `CLAUDE.md`) |
| `settings.example.json` | `permissions.ask` for push/PR + the three hooks |
| `hooks/reminder.sh` | `UserPromptSubmit`: one-paragraph rule reminder on every prompt |
| `hooks/scope-guard.sh` | `PostToolUse`: warns (never blocks) when an edit lands outside the plan's `scope.txt` |
| `hooks/stop-check.sh` | `Stop`: sends Claude back once if files are out of scope or source changed with no test |
| `skills/plan` | Writes `proposal.md`, `tasks.md`, `scope.txt`, `evidence/` and activates the scope |
| `skills/plan-check` | Gates the plan: tests named, "won't change" listed, smallest change, no open questions |
| `skills/build-check` | Gates the code: tests, E2E, lint, diff matches scope, evidence saved |
| `skills/step-back` | Reads the whole diff cold before the PR |
| `claude.gitignore` | Allowlist `.gitignore` so `~/.claude` can be a local git repo |
| `tests/` | Tests for the hooks (`bash tests/run.sh`) |

Needs: Claude Code, `git`, `python3`, `jq` (tests only).

## Start here (10 minutes)

**1. Version your current setup first** so every change can be undone:

```bash
cp -n claude.gitignore ~/.claude/.gitignore
cd ~/.claude && git init && git add -A && git status   # check: no history or credentials staged
git commit -m "Baseline"
```

**2. Add the rulebook.** Already have a `~/.claude/CLAUDE.md`? Merge by hand; keep section 0 (Precedence) at the top.

```bash
cp -n CLAUDE.md lessons.md ~/.claude/
```

**3. Add the hooks and skills** (`-n` never overwrites your files):

```bash
mkdir -p ~/.claude/hooks ~/.claude/skills
cp -n hooks/*.sh ~/.claude/hooks/ && chmod +x ~/.claude/hooks/*.sh
cp -Rn skills/* ~/.claude/skills/
```

**4. Wire them up.** Merge `settings.example.json` into `~/.claude/settings.json` by hand
(`permissions.ask` and `hooks`). If `~` doesn't expand for you, use absolute paths.

**5. Check it works:**

```bash
bash tests/run.sh          # all green
```

Then start a new Claude Code session and ask for anything: the first line of the reply should be a lane (🟢/🟡/🔴).

## How the scope hooks know the plan

The `plan` skill writes the plan's `scope.txt` path into `<repo>/.git/dev-os-scope`.
Both hooks read that pointer; with no pointer they stay silent. It lives inside `.git/`,
so it's never committed. Remove it when the PR is opened.

## Not included

Skill pinning (`skills.lock`, `overlays/`, a sync script) is described in the post (Step 6) but not shipped here.
Add it once you install skills from GitHub and want updates without losing your edits.

## Make it yours

- Edit the skill map (section 4) to name the skills **you** have installed. One owner per job.
- Add project facts to section 7, or keep them in each repo's own `CLAUDE.md`.
- Every time review catches something you should have, add one line to `lessons.md`.
- Add a hook only for a rule you can't afford to have skipped, and add a test for it.

## License

MIT
