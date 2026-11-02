# claude-code-dev-os

A starter kit that makes an AI coding agent behave the same way every day: one rulebook, a relay of named steps
with stops where you decide, and gates that enforce what matters. The rulebook works with any agent that reads
`AGENTS.md` (Codex, Cursor, Copilot and others) or `CLAUDE.md` (Claude Code). The hooks and skills are a deeper,
Claude Code layer; Codex has close equivalents (see [Other agents](#other-agents)).

Posts: **[v1 — one rulebook, a 12-step relay](https://dev.to/dhrupo/how-i-set-up-claude-code-one-rulebook-a-12-step-relay-to-use-it-daily-40gi)** ·
**[v2 — gates, a learning loop, agents that check agents](https://dev.to/dhrupo/dev-os-v2-gates-a-learning-loop-and-agents-that-check-agents-4a9b)**.

## Install for Claude Code (2 commands)

```text
/plugin marketplace add dhrupo/claude-code-dev-os
/plugin install dev-os@dhrupo
```

You get the relay skills (`dev-os:plan`, `dev-os:plan-check`, …), the `scout` and `review-lens` agents, the hooks,
and `gate-install` on the agent's PATH. Then do the three steps in [After install](#after-install): a plugin can't
add your rulebook, your push/PR ask rules or a status line. Using Codex, Cursor or another agent, or prefer files you
can edit? Use [Start here](#start-here) instead.

**Pick one install.** Hooks you already copied into `~/.claude/settings.json` win: the plugin's copy of the same
hook stays quiet, so nothing runs twice. To move from the copied hooks to the plugin, delete the kit's lines from the
`hooks` block in `~/.claude/settings.json`, then restart.

## After install

`RAW=https://raw.githubusercontent.com/dhrupo/claude-code-dev-os/main` (each step skips a file you already have):

1. Rulebook: `for f in CLAUDE.md lessons.md; do [ -e ~/.claude/$f ] || curl -fsSL "$RAW/$f" -o ~/.claude/$f; done`
   (already have a `CLAUDE.md`? merge ours by hand; keep section 0, Precedence, at the top).
2. Ask before push and PR: add to `permissions.ask` in `~/.claude/settings.json`:
   `"Bash(git push:*)", "Bash(git -C * push *)", "Bash(gh pr create:*)"` (rules match the command text, so the
   `git -C` form needs its own line). Until you do, the plugin reminds you once; it reminds again if the rule is removed.
3. Status line (optional): `mkdir -p ~/.claude/hooks; [ -e ~/.claude/hooks/statusline.sh ] || curl -fsSL "$RAW/hooks/statusline.sh" -o ~/.claude/hooks/statusline.sh`,
   `chmod +x` it, and set `statusLine` as in `settings.example.json`. Without it, `ctx-handoff.sh` can't see the
   context % and stays quiet.

## What's inside

**Core: any agent**

| Path | What it does |
|---|---|
| `CLAUDE.md` | The rulebook: precedence, lanes 🟢🟡🔴, 12-step relay, skill map, rules, what is enforced |
| `AGENTS.md` | A link to `CLAUDE.md`, so agents that read `AGENTS.md` get the same rules |
| `lessons.md` | Patterns review caught that you missed; 60-line budget (imported by `CLAUDE.md`) |
| `bin/gate-install` | Per-repo git `pre-commit` gate: no commit while the project's tests fail |

**Claude Code layer: optional**

| Path | What it does |
|---|---|
| `settings.example.json` | `permissions.ask` for push/PR, every hook below, the status line |
| `.claude-plugin/`, `hooks/hooks.json` | The `dev-os` plugin: manifests and the plugin's hook wiring (a test keeps it equal to `settings.example.json`) |
| `hooks/dedupe.sh` | Loaded by every hook: under the plugin, a hook steps aside when you already wired the kit's own copy by hand |
| `hooks/setup-check.sh` | Plugin only, `SessionStart`: says once when the push/PR ask rules are missing (a plugin can't add them) |
| `hooks/reminder.sh` | `UserPromptSubmit`: one-paragraph rule reminder; logs prompts that look like a correction |
| `hooks/scope-guard.sh` (+ `hooks/scope-guard.py`) | `PostToolUse`: warns (never blocks) when an edit lands outside the plan's `scope.txt` |
| `hooks/stop-check.sh` (+ `hooks/stop-check.py`) | `Stop`: sends the agent back once for out-of-scope files, source with no test, or a weakened test |
| `hooks/learn.sh` (+ `hooks/learn.py`) | `Stop`: a logged mistake blocks once until the `reflect` skill runs |
| `hooks/ctx-handoff.sh` | `Stop`: offers a fresh session at ~80% context, or when a second plan starts |
| `hooks/compact.sh` | `SessionStart(compact)`: restates the active plan and next task after compaction |
| `hooks/skill-log.sh` | `PreToolUse(Skill)`: logs skill use, for `learn.sh` and `meditate` |
| `hooks/statusline.sh` | Status line: model + context %; saves the % for `ctx-handoff.sh` |
| `skills/plan` (+ `template/`), `plan-check`, `build-check`, `step-back` | The relay's gates; the plan template is proposal, tasks, scope.txt, evidence/ |
| `skills/pre-merge-review`, `post-pr-review` | Deep review of your branch (lenses + a verifier per finding); review of someone else's PR, each finding proven by running it |
| `skills/reflect` | Turns a mistake into a check, a skill edit or a lesson |
| `skills/meditate` | Audits rules and lessons for stale, duplicate and contradicting lines |
| `agents/scout.md` | Read-only finder for one angle (spawn 2-4 at once) |
| `agents/review-lens.md` | Read-only reviewer for one lens (Skeptic, Architect, Minimalist) or one finding's verifier |
| `tests/` | 239 checks for every hook, the gate and the kit shape (`bash tests/run.sh`) |

Needs: `git`, `bash`, `python3`, `jq`.

## What the plugin runs

Every hook is a local shell script (some start Python 3 from `hooks/*.py`). "State" is `$DEV_OS_STATE`, default
`~/.claude/state`. `.git/` means the repo's git folder (`git rev-parse --absolute-git-dir`; in a worktree,
`.git/worktrees/<name>/`). Git commands only read your work: `rev-parse`, `status`, `diff`, `cat-file` (`git status`
may refresh `.git/index`, as it always does).

| Hook | Event | Reads | Writes | Can it stop Claude? |
|---|---|---|---|---|
| `reminder.sh` | `UserPromptSubmit` | your prompt | a prompt that looks like a correction: its first 120 bytes to `state/learn-<session>.jsonl` | No; adds a rule reminder |
| `skill-log.sh` | `PreToolUse(Skill)`, `UserPromptExpansion` | the skill name | skill, folder and session id to `state/skill-usage.jsonl` | No |
| `scope-guard.sh` | `PostToolUse` (Edit, Write, MultiEdit, NotebookEdit) | the edited path, `.git/dev-os-scope`, the plan's `scope.txt` | nothing | No; adds a warning |
| `stop-check.sh` | `Stop` | `git status`/`diff`, the plan's `scope.txt` | `.git/dev-os-scope.warned`, `state/learn-<session>.jsonl` | Once per new set of problems |
| `learn.sh` | `Stop` | `state/learn-<session>.jsonl`, `state/skill-usage.jsonl` | `state/learn-<session>.warned` | Once per new set of mistakes |
| `ctx-handoff.sh` | `Stop` | `.git/dev-os-scope`, `state/ctx-<session>.txt` | `state/plans-<session>.txt`, `state/ctx-<session>.asked`; deletes `state/ctx-*`, `learn-*` and `plans-*` files 8 or more days old | Once per new plan, once at 80% context |
| `compact.sh` | `SessionStart(compact)` | `.git/dev-os-scope`, the plan's `tasks.md` | nothing | No; restates the plan |
| `setup-check.sh` | `SessionStart(startup)` | your `settings.json` | `state/setup-check.warned` | No; one notice |

`dedupe.sh` runs inside each hook and only reads: your `settings.json` and the hook scripts it names (to see if they
are the kit's own). No network calls. The plugin never edits your settings, never commits and never pushes.
"Stop Claude" means a `Stop` hook sends Claude back to finish one step.

## Start here

Run everything from the kit folder; `KIT` is where you cloned it.

**1. Version your setup first** so every change can be undone:

```bash
KIT=$(pwd)
cp -n "$KIT/claude.gitignore" ~/.claude/.gitignore
(cd ~/.claude && git init && git add -A && git status)   # check: no history or credentials staged
(cd ~/.claude && git commit -m "Baseline")
```

**2. Add the rulebook** (already have one? merge by hand; keep section 0, Precedence, at the top):

```bash
cp -n "$KIT/CLAUDE.md" "$KIT/lessons.md" ~/.claude/
mkdir -p ~/.claude/bin; cp -n "$KIT/bin/gate-install" ~/.claude/bin/
```

**3. Turn on the test gate in a project** (one line: the command that runs that project's tests):

```bash
cd ~/code/my-app
echo 'npm test' > .dev-os-test
~/.claude/bin/gate-install
git commit -am "try it"       # refused while npm test fails
cd "$KIT"
```

The hook runs the command with `pipefail` and reads its own exit code, so `npm test | tail` cannot hide a failure.
An empty or missing `.dev-os-test` refuses the commit instead of passing silently. Git's own index variables are
cleared first, so a test suite that runs `git` itself works. It never overwrites a `pre-commit` hook it did not write
(husky, pre-commit), and it refuses a global `core.hooksPath`: add the one line it prints to that hook instead.
`.dev-os-test` is code from the repo that runs on every commit, like `npm test`: in a shared repo, read it after a
pull that changes it.

**4. Claude Code layer** (`-n` never overwrites your files; on macOS it exits 1 when it skips one, hence `;`):

```bash
mkdir -p ~/.claude/hooks ~/.claude/skills ~/.claude/agents
cp -n "$KIT"/hooks/*.sh ~/.claude/hooks/; chmod +x ~/.claude/hooks/*.sh
cp -n "$KIT"/hooks/*.py ~/.claude/hooks/
cp -Rn "$KIT"/skills/* ~/.claude/skills/; cp -n "$KIT"/agents/*.md ~/.claude/agents/
```

Merge `settings.example.json` into `~/.claude/settings.json` by hand (`permissions`, `hooks`, `statusLine`).
Already have a status line? Keep it, and add the line that saves the context % for `ctx-handoff.sh`:
`[ -n "$USED" ] && mkdir -p ~/.claude/state && echo "${USED%.*}" > ~/.claude/state/ctx-$SID.txt`
(`USED` = `.context_window.used_percentage`, `SID` = `.session_id` from the status line's JSON input).

**5. Check it works:**

```bash
bash "$KIT/tests/run.sh"          # all green
```

Start a new session and ask for anything: the first line of the reply is a lane (🟢/🟡/🔴).

## Other agents

Checked against official docs on 2026-11-01; tools move fast, so re-check before relying on a detail.

- **Codex CLI** reads `~/.codex/AGENTS.md`, then one `AGENTS.md` per folder from the repo root down (closer files win;
  32 KiB total by default). Use the same rulebook: `ln -s ~/.claude/CLAUDE.md ~/.codex/AGENTS.md`.
  Skills live in `~/.agents/skills` (symlinked folders work); Codex hooks use the same event names and the
  same `Stop` → `{"decision":"block"}` shape, configured in `~/.codex/hooks.json`. To make `git push` ask first, use a
  `prefix_rule` with `decision = "prompt"` in `~/.codex/rules/` (marked experimental).
- **Claude Code** reads `AGENTS.md` only in a repo with no `CLAUDE.md`; this kit keeps `CLAUDE.md` as the source.
- `@lessons.md` imports are a Claude Code feature: through the `AGENTS.md` link, Codex reads the rulebook but not
  `lessons.md`. Paste short lessons into the rulebook if you rely on Codex.
- **Cursor, GitHub Copilot and others** read `AGENTS.md` ([agents.md](https://agents.md)); hooks exist but use their
  own config.
- **The test gate is plain git**, so it works the same whatever agent (or person) commits.

## Project memory: graph first

Rule 8 tells the agent to ask a code graph "who calls this?" before grepping. Two options, both usable from any agent:
[graphify](https://github.com/Graphify-Labs/graphify) (CLI, `uv tool install graphifyy`) and
[code-review-graph](https://github.com/tirth8205/code-review-graph) (MCP server). Build the graph once per project and
refresh it after big merges. What was *learned* lives in `lessons.md` and the plan folders, not in the graph.

## How the hooks know the plan

The `plan` skill writes the plan's `scope.txt` path into `<repo>/.git/dev-os-scope`. The hooks read that pointer;
with no pointer they stay silent. It lives inside `.git/`, so it is never committed. Remove it when the PR is opened.

## Upgrading a 2.1.0 copy install

2.1.1 runs the Python of three hooks from `hooks/*.py`, not `python3 -c`. So a `json.py` in your project can't replace
Python's own, and `-I` also ignores one next to the hook. `cp -n` keeps your old copies, so overwrite them:

```bash
cp "$KIT"/hooks/{learn,scope-guard,stop-check}.{sh,py} ~/.claude/hooks/
```

A plugin-only install gets this with the plugin update. If you also wired copied hooks by hand, run the command above:
the plugin steps aside for them.

## Upgrading from v1

Nothing was renamed. Do steps 2-4 above (with `-n` they only add what is missing), then replace the two v1 hooks
and three v1 skills that changed, since `cp -n` keeps your old copies (the learning loop needs the new hooks; the
plan skill now copies its template, plan-check gained check 5, and build-check runs `/code-review`):

```bash
(cd ~/.claude && git add -A && git commit -m "Before v2")   # one commit to undo with git revert
cp "$KIT/hooks/reminder.sh" "$KIT/hooks/stop-check.sh" "$KIT/hooks/stop-check.py" ~/.claude/hooks/
cp "$KIT/skills/plan/SKILL.md" ~/.claude/skills/plan/; cp "$KIT/skills/plan-check/SKILL.md" ~/.claude/skills/plan-check/
cp "$KIT/skills/build-check/SKILL.md" ~/.claude/skills/build-check/
```

Merge the new `settings.example.json` blocks, and diff your `CLAUDE.md` against the new one (sections 1, 3, 4, 5
and 6 grew).

## Known gaps

- `permissions.ask` matches command text: the kit asks for `git push`, `git -C <dir> push` and `gh pr create`, but
  other spellings (`git -c x=y push`, `env … git push`) slip past. The test gate and branch protection are the backstops.
- Skill pinning (`skills.lock`, overlays, a sync script) is described in the v1 post but not shipped here.

## Make it yours

- Edit the skill map (section 4) to name the skills **you** have installed. One owner per job.
- Rule 3 is the ladder from [ponytail](https://github.com/DietrichGebert/ponytail) (MIT); install its skills for the
  full version (`ponytail` while building, `ponytail-review` at the tidy step).
- Add project facts to section 7, or keep them in each repo's own `CLAUDE.md` / `AGENTS.md`.
- When review catches something, run `reflect`: a test or hook beats a new line in `lessons.md`.
- Add a hook only for a rule you can't afford to have skipped, and give it a test.

## License

MIT
