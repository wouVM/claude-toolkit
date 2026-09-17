---
name: project-setup
description: >
  Seed a repo with the toolkit's working conventions so every new project starts set up
  properly: a CLAUDE.md built from the conventions template (kernel mode, proportionality,
  lib-first, the trap book, the landing gates), the judge rubric at .claude/gemini-judge.md,
  the TRAPS.md trap book and FAULT-CATALOGUE.md skeletons, and the .claude/settings.json
  entries that auto-install this toolkit's plugins for everyone who clones the repo. Use in
  a fresh or existing repo when the user says "/project-setup", "set up this project",
  "seed the conventions", "bootstrap claude for this repo", or "give this repo the toolkit
  setup". Merges with an existing CLAUDE.md, never overwrites one.
allowed-tools: Bash, Read, Write, Edit, Glob, AskUserQuestion
---

# /project-setup - seed a repo with the toolkit conventions

The templates live in the `templates/` directory next to this SKILL.md. Each is a starting
point to be FILLED IN and TRIMMED for the repo at hand, never copied blind: a convention the
project will not actually follow is prompt-surface rot.

## Step 1: Look around

From the repo root (`git rev-parse --show-toplevel`; if not a git repo, ask whether to `git init`):

- Does `CLAUDE.md` exist? Read it if so - you will MERGE, never overwrite.
- Read enough to fill the placeholders yourself: the project name and one-line purpose
  (package.json / pyproject / README), the layout (top-level dirs), the runtime (Workers /
  Node / browser / native), and the distribution model (open source vs commercial - it drives
  the license gate wording).
- Check `.claude/settings.json` for existing `enabledPlugins` / `extraKnownMarketplaces`.

## Step 2: Ask what to seed

Ask via AskUserQuestion (multiSelect) which pieces they want:

1. **CLAUDE.md conventions** (from `templates/CLAUDE-template.md`)
2. **Judge rubric** at `.claude/gemini-judge.md` (from `templates/gemini-judge.md`)
3. **Trap book + fault catalogue** (`TRAPS.md`, `FAULT-CATALOGUE.md` skeletons)
4. **Team auto-install** - commit `extraKnownMarketplaces` + `enabledPlugins` to
   `.claude/settings.json` so everyone who clones gets these plugins automatically
5. **The role fence** - the `builder-model-guard.sh` PreToolUse hook (from
   `templates/builder-model-guard.sh`), which stops a coordinator-model session from editing build
   code and points it at `/build` instead
6. **The ticket pickup policy** at `.claude/pickup.json` (from `templates/pickup.json`), which is
   what `workflow:intake` and `workflow:pickup` read: the tracker, the repos and their base
   branches, the verify command, and the per-route autonomy dial

Default recommendation: all five of 1-5 for a fresh repo; for an existing repo with its own
CLAUDE.md, recommend 2-5 plus a conventions MERGE. Offer 6 only where the project actually has a
tracker that work arrives through: the pickup skills stop cleanly when the file is absent, so a
half-filled one is worse than none.

## Step 3: Seed

- **CLAUDE.md**: fill every `<PLACEHOLDER>` from what you read in Step 1 (ask only for what
  you genuinely cannot infer, e.g. hard lines / protected environments). If a CLAUDE.md
  already exists, do not replace it: propose the missing sections as an addition, show the
  user the diff-sized summary, and apply on their yes. Trim agreements that cannot apply
  (e.g. drop the migrations line for a repo with no database).
- **Judge rubric**: fill the `<PROJECT-NAME>` and project-description placeholders; keep the
  dimensions intact. Write to `.claude/gemini-judge.md`.
- **Ledgers**: write `TRAPS.md` and `FAULT-CATALOGUE.md` skeletons at the repo root (skip any
  that already exist). Also seed an empty `DEFERRED.md` with a one-line header if the user took
  the CLAUDE.md piece (it references the ledger).
- **Team auto-install**: merge (never clobber) into `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": [
    { "name": "<marketplace-name>", "url": "<this toolkit's git URL>" }
  ],
  "enabledPlugins": { "workflow": true, "design": true }
}
```

  Resolve the marketplace name and URL from the installed marketplace itself
  (`~/.claude/plugins/` config, or ask the user). Omit `design` if the repo has no UI. If the
  toolkit has no pushed remote yet, say so and skip this piece rather than writing a dead URL.

- **The role fence**: copy `templates/builder-model-guard.sh` to `.claude/hooks/`, `chmod +x` it, and
  set its two constants from what you learned in Step 1: `COORDINATOR_PATTERN` (the model id that must
  not build - ask the user which model they coordinate on) and `BUILD_DIRS` (this repo's actual build
  directories, as a `dir/*|dir/*` case pattern - use the real top-level layout, not the template's
  guesses). Then merge the `PreToolUse` hook entry into `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Edit|Write",
        "hooks": [ { "type": "command",
                     "command": "\"$CLAUDE_PROJECT_DIR/.claude/hooks/builder-model-guard.sh\"",
                     "timeout": 10,
                     "statusMessage": "Checking the role fence" } ] }
    ]
  },
  "env": { "CLAUDE_CODE_SUBAGENT_MODEL": "opus" }
}
```

  `CLAUDE_CODE_SUBAGENT_MODEL` makes the builder model the subagent default. Do NOT use the `_FORCE`
  variant: it would also override a per-call `model:`, which is how a scout gets the cheap model.
  Tell the user the fence is live and that `/build` is the path across it.

- **The ticket pickup policy**: copy `templates/pickup.json` to `.claude/pickup.json` and replace
  every value with this project's own. The tracker block needs the real project key and the exact
  status names as the tracker spells them; `repos` needs each sub-repo's path and base branch;
  `verify` needs the command the project actually runs. Set `diagnosis_kinds` to the kinds this
  project can tell apart, and give each one a route. A route whose fix path a human owns takes
  `"skill": null`, `"max_autonomy": "plan"`, and a `reason` naming that owner, which is the dial
  Wouter asked for: flipping one route to `"pr"` is the whole change needed to hand that area to
  automation while the owner is away. Ask for the status names and the owners rather than guessing
  them, and tell the user that the signature (moving a ticket to `signed_status`) is theirs alone
  and the only thing that authorises a pickup.

## Step 4: Report

List exactly what was written or merged, path by path, and the one follow-up that matters:
commit the seeded files so the setup travels with the repo.
