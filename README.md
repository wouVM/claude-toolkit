# claude-toolkit

A Claude Code plugin marketplace: portable working conventions, review gates, and design skills,
lifted out of project repos so every project (and every teammate) gets them from one place.

## Install

```
/plugin marketplace add <owner>/claude-toolkit     # or a local path while developing
/plugin install workflow@claude-toolkit
/plugin install design@claude-toolkit
```

Skills arrive namespaced: `workflow:gemini`, `workflow:issue`, `design:gsap`, etc.
Invoke them as slash commands (`/workflow:project-setup`) or let them trigger by description.

## What's inside

### `workflow` - the landing gates

| Skill | What it does |
|---|---|
| `gemini` | Gemini 3.1 Pro (via the Antigravity CLI `agy`) as an independent reviewer: review (PASS/FAIL gate), challenge, consult, and judge (proportion + honesty, driven by a per-repo rubric at `.claude/gemini-judge.md`) |
| `springclean` | An adversarial taste panel (five lenses: overengineering, hand-rolling, KISS, fake tests, fronting) that grades a diff "achieved / not achieved" |
| `issue` | Capture any loose thought as a classified, duplicate-checked, cross-linked GitHub issue with a `gh#N` handle |
| `project-setup` | Seed a repo with the conventions: CLAUDE.md template, judge rubric, TRAPS.md trap book, FAULT-CATALOGUE.md, and the settings that auto-install this toolkit for everyone who clones |
| `spec-sharpen` | Spec-driven development's spec-side gate: multi-pass requirements review (TPM lens, code-grounded dev lens, cold exhaust pass, premise reconcile with file:line citations) until a ticket/issue/spec is signable |
| `build` | The cheap path across the role boundary: hand a spec to a builder subagent with the allowlist, no-crawl rule, budget and report-back prompt pre-written, then review only the diff |
| `digest` | The read-side counterpart: send a long PDF, transcript or doc-set to a cheap scout and get findings back, instead of pulling it into the coordinator's context |

And three agents encoding the role-to-model cost discipline (invoke via the Agent tool; the
description on each is the router - dispatch by role, never downgrade the whole session):

| Agent | Model | Role |
|---|---|---|
| `explorer` | Sonnet | Cheap read-only fan-out: repo search, scouting, tracing - returns conclusions, not file dumps |
| `builder` | Opus | Executes a specced chunk foundation-first, tests included; escalates design questions instead of improvising |
| `reviewer` | (inherits) | One independent panel seat, never the builder; charter comes from the dispatch prompt: a correctness review of a range, or a single springclean taste lens |

**The role fence.** The cost discipline (coordinator directs, builder executes, scout explores) is a
mechanism here, not a rule in a file: `project-setup` seeds a `PreToolUse` hook that denies
coordinator-model edits to build code and points at `/build` instead. It fails open on every unknown and
never fences a subagent. `/digest` covers the read side, which no hook can fence — blocking reads would
break the coordinator's own job of reviewing a diff.

The workflow this encodes: work lands through TWO gates - a correctness gate (every independent
reviewer the machine has, in parallel; one verified defect overrides a majority pass) and ONE
taste gate (`/gemini judge` for routine diffs, `/springclean` for load-bearing ones). Conventions
live in each repo's CLAUDE.md; `project-setup` seeds them.

Requirements: `gh` (GitHub CLI) for `issue`; `agy` (Antigravity CLI, a Google Gemini
subscription) for `gemini`. Skills degrade gracefully and tell you what is missing.

### `design` - frontend and design skills

`gsap` (animation, with reference docs), `minimalist-ui`, `premium-frontend-ui`,
`industrial-brutalist-ui`, `mobile-app-ui-design`, `swiftui-skills`, `product-film-craft`.

## Set up a team repo once, for everyone

In any project, run `/workflow:project-setup` and pick "team auto-install": it commits
`extraKnownMarketplaces` + `enabledPlugins` to that repo's `.claude/settings.json`, so every
teammate who clones the repo gets this toolkit registered and enabled automatically.

## Licenses

The toolkit's own content is MIT. Bundled third-party skill material keeps its upstream license:
`design/skills/gsap` includes GreenSock's MIT-licensed docs; `design/skills/swiftui-skills` is an
MIT-licensed packaging that fetches Apple documentation at setup time (docs not vendored).
