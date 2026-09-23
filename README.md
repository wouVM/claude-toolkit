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
| `project-setup` | Seed a repo with the conventions: CLAUDE.md template, judge rubric, TRAPS.md trap book and FAULT-CATALOGUE.md (with starter entries to keep or delete), the testing rule, an optional Stop-hook completion check, a read-only `tools-check.sh` for integration credentials, and the settings that auto-install this toolkit for everyone who clones |
| `spec-sharpen` | Spec-driven development's spec-side gate: multi-pass requirements review (TPM lens, code-grounded dev lens, cold exhaust pass, premise reconcile with file:line citations) until a ticket/issue/spec is signable, leaving the reasoning as an append-only comment trail on the ticket (one comment per lens with every finding's fate, one for the cited premises) so a deferred or killed finding stays reviewable instead of vanishing |
| `build` | The cheap path across the role boundary: hand a spec to a builder subagent with the allowlist, no-crawl rule, budget and report-back prompt pre-written, then a separate test writer and a comment pass on the added lines, then review only the diff |
| `test-writing` | Tests that earn their lines, written by a separate agent after the build: WRITE turns the acceptance criteria into one test per rule, spent top-down on a risk ladder; AUDIT grades a branch's tests keep / merge / shrink / cut / gap. Ships `pr_test_stats.py` (size split, test-to-code ratio, diff coverage) for the PR description's Details section |
| `digest` | The read-side counterpart: send a long PDF, transcript or doc-set to a cheap scout and get findings back, instead of pulling it into the coordinator's context |
| `intake` | An incoming request becomes one diagnosed ticket: symptom split from the requester's inference, a verdict with `file:line` evidence for every claim about current behaviour, a relation scan over the tracker that catches the duplicate of an open ticket and the REGRESSION of a closed one, sharpened, filed as a DRAFT for a human to sign |
| `pickup` | A human-signed ticket becomes a branch: a preflight that proves the tracker accepts the configured labels and that the poll query is well-formed (zero tickets on an unverified query is indistinguishable from no work to do), claim it so parallel runs cannot collide, isolate a worktree, route by diagnosis kind to the project's fix skill, verify, then a bounded review loop (every configured reviewer in parallel, one verified defect blocks, a second round that fails on a brand-new defect escalates to the taste gate instead of a third) and land only as far as that route's `max_autonomy` allows, posting each step (claim, verify, review round, PR) as a comment on the ticket. Never merges |
| `coordinate` | When several chats work on related tickets, one coordinator chat owns the outcome: a session-state file written before compaction (role, PR table with heads, next steps, settled decisions, open items, access notes), owner chats messaged before their worktree is touched and when done, their "all green" verified rather than relayed, the unmerged combination deployed to staging with a per-ticket note of what staging cannot prove, and the human handed only their own steps (merges, tags, production approvals and writes, messages to people) |
| `worktree` | The isolation and conflict discipline: one worktree per ticket per sub-repo off a freshly fetched base, conflicts detected with a write-nothing `git merge-tree` dry run and handed to a human, never resolved |

And three agents encoding the role-to-model cost discipline (invoke via the Agent tool; the
description on each is the router - dispatch by role, never downgrade the whole session):

| Agent | Model | Role |
|---|---|---|
| `explorer` | Sonnet | Cheap read-only fan-out: repo search, scouting, tracing - returns conclusions, not file dumps |
| `builder` | Opus | Executes a specced chunk foundation-first and keeps the existing suite green, leaving the new tests to a separate `test-writing` agent; escalates design questions instead of improvising |
| `reviewer` | (inherits) | One independent panel seat, never the builder; charter comes from the dispatch prompt: a correctness review of a range, or a single springclean taste lens |

**The role fence.** The cost discipline (coordinator directs, builder executes, scout explores) is a
mechanism here, not a rule in a file: `project-setup` seeds a `PreToolUse` hook that denies
coordinator-model edits to build code and points at `/build` instead. It fails open on every unknown and
never fences a subagent. `/digest` covers the read side, which no hook can fence: blocking reads would
break the coordinator's own job of reviewing a diff.

**The ticket chain.** `intake` and `pickup` are two halves with a human signature between them: a
request becomes a diagnosed draft ticket, a person moves it to the signed status, and only then may a
run take it. The mechanism is the same in every project, so the policy lives in one per-project file,
`.claude/pickup.json` (seeded by `project-setup`): which tracker, which repos, which fix skill per
diagnosis kind, a `max_autonomy` dial per route (`plan` / `branch` / `pr`), which reviewers gate the
diff and how many rounds they get, how far back to look for the closed ticket a request is a
regression of, and whether the sharpening trail posts as ticket comments or stays in a sidecar.
Merging is not a level.

The workflow this encodes: work lands through TWO gates - a correctness gate (every independent
reviewer the machine has, in parallel; one verified defect overrides a majority pass) and ONE
taste gate (`/gemini judge` for routine diffs, `/springclean` for load-bearing ones). Conventions
live in each repo's CLAUDE.md; `project-setup` seeds them.

Requirements: `gh` (GitHub CLI) for `issue`; `agy` (Antigravity CLI, a Google Gemini
subscription) for `gemini`. Skills degrade gracefully and tell you what is missing.

### `design` - frontend and design skills

`gsap` (animation, with reference docs), `minimalist-ui`, `premium-frontend-ui`,
`industrial-brutalist-ui`, `mobile-app-ui-design`, `swiftui-skills`, `product-film-craft`.

## Changes

### workflow 0.9.0

- `coordinate`: a new skill for the chat that owns a multi-chat release, from the session-state file to
  the human's step list, including staging tests of the unmerged combination and "done means switched on".
- PR descriptions open with four plain sections a non-developer reviewer can follow (Why, What changes,
  How it was tested, Review in this order with a Check: line each); the technical sections move under
  Details. Title `[TICKET] - plain description`, never the branch name.
- Review briefs (the `reviewer` agent, `build`, `pickup`, `springclean`, `gemini review`) name the
  neighbouring rules and contracts a change touches and ask whether new and old can both hold.
- `project-setup` seeds two optional pieces: a `Stop` prompt-hook completion check that always lets the
  assistant wait on work it launched, and `tools-check.sh`, which says per integration whether a
  credential is missing, malformed, rejected (401) or under-scoped (403) without printing it.
- TRAPS.md and FAULT-CATALOGUE.md ship starter entries: done means switched on, file-copy deploys revert
  hand edits, copied blocks drift, the "flaky" test that is the database's mount, and status claims
  without proof.

## Set up a team repo once, for everyone

In any project, run `/workflow:project-setup` and pick "team auto-install": it commits
`extraKnownMarketplaces` + `enabledPlugins` to that repo's `.claude/settings.json`, so every
teammate who clones the repo gets this toolkit registered and enabled automatically.

## Licenses

The toolkit's own content is MIT. Bundled third-party skill material keeps its upstream license:
`design/skills/gsap` includes GreenSock's MIT-licensed docs; `design/skills/swiftui-skills` is an
MIT-licensed packaging that fetches Apple documentation at setup time (docs not vendored).
