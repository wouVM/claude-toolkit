# Getting started with the `workflow` plugin

One page for a team that has never used it. The idea in one sentence: a human signs WHAT a ticket
must do, agents carry it to a reviewed PR, and a human merges it.

## 1. Install

In Claude Code:

```
/plugin marketplace add wouVM/claude-toolkit     # or a local path while developing
/plugin install workflow@claude-toolkit
/plugin install design@claude-toolkit
```

Skills arrive namespaced (`workflow:pickup`, `workflow:build`, ...). Invoke them as slash commands
or let them trigger by their description.

## 2. Set up the repo

In the repo, run:

```
/workflow:project-setup
```

It seeds a `CLAUDE.md` from the conventions template, `TRAPS.md` and `FAULT-CATALOGUE.md`, the
testing rule, the role-fence hook, a read-only tools check, and `.claude/pickup.json`: the one file
that holds your project's policy (tracker, repos, verify command, routes, reviewers, review rounds).
Fill in the placeholders and trim what your team will not follow. It merges with an existing
`CLAUDE.md` and never overwrites one.

## 3. How a ticket flows

1. **Intake** (`/workflow:intake`). A request (an email, a complaint, a file) becomes one diagnosed
   ticket: the reporter's symptom split from their guess, every claim about today's behaviour cited
   with `file:line`, and a scan for duplicates and regressions. It is filed as a DRAFT.
2. **Ticket-format** (`/workflow:ticket-format`). The house format: user story, business
   requirements, acceptance criteria, what staging cannot prove, out of scope. It then runs
   spec-sharpen (`/workflow:spec-sharpen`): independent lenses (product, code-grounded dev, a cold
   pass, a premise reconcile) until the ticket is signable, each finding with a fate (DECIDE, DEFER,
   KILL) posted as a comment so nothing vanishes. It ends with the ready check.
3. **Tech-design** (`/workflow:tech-design`), only if a trigger fires (several subsystems, a new
   dependency, a migration, a changed contract, a new long-lived concept): options with trade-offs
   and one recommendation, posted on the ticket as a comment and picked before anyone signs.
4. **A human signs.** A person moves the ticket to the signed status. No agent ever does this.
5. **Pickup** (`/workflow:pickup`). From here no person drives each step:
   - claim the ticket, so a parallel run cannot take it;
   - isolate a worktree (`workflow:worktree`);
   - route by the ticket's diagnosis kind to the fix skill set in `pickup.json`;
   - the route's fix skill does the work, with the design (if the ticket has one) as part of the
     spec. For code it typically runs `/workflow:build`: a builder subagent inside a file allowlist,
     then a separate test writer (`workflow:test-writing`);
   - verify: the project's verify command, its output read, not summarised;
   - review loop: fresh reviewers who did not write the code. How many seats is sized by
     `review.full_panel_when` in `.claude/pickup.json`: a small change gets one reviewer, a risky or
     large one the full panel. Every finding gets a fate (FIXED, DEFERRED or DISMISSED, with a
     reason) before the next round, and the rounds are capped;
   - taste gate (`/workflow:springclean` or `/workflow:gemini judge`) when fixes keep adding
     machinery, to ask whether the shape is right, not just whether it works;
   - QA, if the project has one: a fresh agent exercises the change as a user would and files
     defects back into the loop;
   - PR, as far as the route's `max_autonomy` allows (`plan`, `branch` or `pr`).
6. **A human merges.** Merging is not an autonomy level. Agents never merge.

When several chats build tickets for the same release, one chat runs `/workflow:coordinate`: it
owns the outcome, keeps a short state file that survives compaction, and tests the combination.

## 4. The roles

| Role | Does | Never does |
|---|---|---|
| Coordinator (your main chat) | Directs, writes briefs, reviews diffs, decides done, owns the result | Bulk-reads code; writes build code itself |
| Explorer (`workflow:explorer`, cheap model) | Reads, searches, traces, reports with `file:line` | Edits or decides |
| Builder (`workflow:builder`) | Implements the spec inside the allowlist, runs the tests | Makes design choices, reviews its own work |
| Reviewer (`workflow:reviewer`) | Judges work it did not write, one charter per seat | Reviews its own output |

The coordinator owns the outcome even when every line was written by an agent. An agent's "all
green" counts only after its pasted output has been read.

## 5. What the human gets

- PRs to review and merge.
- Environment checks: what only staging or production can show, listed per ticket.
- Business questions: what a user or the client gets, batched, each with a recommended answer.
  Technical choices are the coordinator's.

Nothing else. Everything an agent can do is done, not handed over.

## 6. Five rules that matter most

1. **Green is a claim, not a fact.** Every "done", "fixed" or "live" names its proof: the output,
   the commit, the `file:line`, the time from `date`.
2. **Nobody reviews their own work.** The builder, the test writer and each reviewer are separate
   agents.
3. **Every finding gets a fate before the next round.** Unfated findings are how review loops
   spiral.
4. **Size the process to the change.** One reviewer for a small diff; the full panel only where
   `full_panel_when` says so.
5. **Done means exercised for real.** One real request on the target environment, not "it works
   locally".
