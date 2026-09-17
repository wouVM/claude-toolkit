---
name: pickup
description: >
  Take a human-signed ticket off the tracker and carry it to an open PR without a person driving
  each step: poll for signed tickets, CLAIM one so a parallel run cannot take it, isolate a
  worktree, route by the ticket's diagnosis kind to the project's configured fix skill, run the
  project's verify command, put the diff through a bounded review loop with the project's own
  reviewers before it lands, and land only as far as that route's max_autonomy allows. Use when
  the user says "/pickup", "pick up the next ticket", "work the queue", "anything signed off
  yet", "take FB-123", "review it before the PR", "run the reviewers on this branch", or
  schedules an unattended run over a tracker. Reads its policy from
  .claude/pickup.json and stops with an explanation if that file is absent. It NEVER merges,
  never resolves a conflict, and never signs a ticket itself (that is the human's act, and the
  ticket half is workflow:intake).
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, AskUserQuestion, Skill
---

# /pickup - a signed ticket becomes a branch, and reports back

ELI16 first: the tracker is the queue and a human's signature is the go-ahead. This skill reads the
queue, takes exactly one ticket, marks it taken so another run cannot grab the same one, does the
work in its own isolated copy of the repo, runs the tests, puts the result in front of the
project's reviewers and fixes what they ground in a file, and pushes as far as the project's dial
says it may. The review loop is bounded on purpose: it gets a small number of rounds and then hands
the work to a human rather than grinding. Everything it learns goes back ONTO THE TICKET, because by
construction nobody is watching the session it runs in.

## Step 0: the config, or stop

Read `.claude/pickup.json` from the repo root. Everything policy-shaped lives there: the tracker and
its statuses, the repos and their base branches, the worktree root, the verify command, the
diagnosis kinds, the route per kind, the PR skill, and the `review` block (which reviewers to run,
which taste gate to escalate to, how many rounds are allowed). If it is absent, print the fields that
would be needed and stop. Do not improvise a tracker query, a base branch, or a fix path: this skill is
identical in every project and only the config makes it correct in one.

## Step 1: POLL (read-only)

Find candidates: in `signed_status`, carrying `pickup_label`, with no linked PR and without
`in_flight_label`. Shaped as JQL:

```
project = FB AND status = "Ready for Dev" AND labels = "auto-fix"
  AND labels != "in-flight" AND issueFunction not in linkedIssuesOf("...")
```

Use the project's tracker MCP or CLI. Take ONE ticket unless the user explicitly asked for more.
Polling writes nothing, to the tracker or the repo, so a poll that finds nothing is a clean no-op
and a safe thing to run on a schedule.

## Step 2: CLAIM, before any work

Add `in_flight_label` and, if `in_progress_status` is configured, transition the ticket. Only then
start.

The order is the whole point. Two scheduled runs, or a scheduled run and a person, can poll the same
queue seconds apart; if the claim happens after the work, both do the work and one of them discovers
it at push time, having burned a full run. The label is a cheap lock in a place both runs can see.
If the claim write fails, stop: an unclaimed ticket is not yours.

## Step 3: ISOLATE

Create the worktree with `workflow:worktree`, in the sub-repo the ticket touches, branched from that
repo's freshly fetched `base`. That skill owns the isolation and conflict discipline; do not
hand-roll a `git checkout` here.

## Step 4: ROUTE by diagnosis kind

Look up the ticket's diagnosis kind in `routes`. Each route names a project skill and a
`max_autonomy`.

- A route with a `skill` delegates to it. That skill knows the project's fix path; this one does not
  and must not invent one.
- A route with `"skill": null` (or a kind that is not in `routes` at all) STOPS. Post a plan on the
  ticket: what you found, what you would change, what verification it would need, and the route's
  `reason` if it has one. Then stop, and leave the ticket claimed with the plan visible.

An unconfigured kind is a deliberate gap, usually because a human owns that area. Improvising into
it is how an automated chain starts writing code nobody asked it to write, in a part of the system
whose owner was never consulted. A plan on the ticket is useful to that owner; a surprise diff is
not.

## Step 5: VERIFY

Run the project's `verify` command, exactly as configured, and read the real output.

**A failing suite is a finding, not an obstacle.** Stop, post the failure output on the ticket, leave
the worktree in place, and do not try to make it green by weakening a test. A red suite on a fix is
information: either the fix is wrong, or the suite pins something the ticket did not account for.
Both are things a human needs to see, and both are destroyed by a run that quietly adjusts the
assertion.

## Step 6: REVIEW, in a loop that is allowed to end badly

This step runs when the route's `max_autonomy` is `branch` or `pr`. A `plan` route produced no diff,
so there is nothing to review and the loop is skipped. If `.claude/pickup.json` has no `review`
block, skip the loop too and SAY SO in the report: a project with no configured reviewers has none,
and inventing one is worse than naming the gap.

**Dispatch every reviewer in `review.reviewers` IN PARALLEL, in one message.** Each gets the commit
range and reads the repo itself; none is ever handed pasted code. A configured reviewer is a skill
the project has (`codex review`, `gemini review`) or this plugin's `reviewer` agent, and reviewers
are always dispatched fresh, never the agent that wrote the code. The builder does not review itself,
including when the builder is the thing that just fixed a reviewer's finding.

**A single VERIFIED defect blocks, and a majority does not clear one.** If any reviewer reports a
P0 or P1 it can ground in a file, the work goes back to the route's fix skill with that defect as its
input, and the verify command runs again afterwards: a fix that breaks the suite is worse than the
defect it repaired. Never weaken or delete a test to clear a finding. That destroys the exact
information this run exists to produce.

**A second round is allowed. A third is the wrong instrument.** When a fix fails a SECOND review
round with a BRAND-NEW defect, one that round N-1's fix introduced, stop patching and run
`review.taste_gate` (`springclean`, `gemini judge`) instead, and report its verdict on the ticket.
The reason is structural: a correctness reviewer can only ever ADD machinery, because "should this
exist?" is on no correctness reviewer's ballot. A wrong design under repeated correctness review
therefore gets HARDENED rather than rejected, and each round's fix mints the next round's defect. The
tell is the PATTERN (round N failing on what round N-1's fix introduced), not the severity of any
single finding, which is why the escalation is to a taste gate and not to a third correctness round.

**`review.max_rounds` (default 2) caps the loop whatever the findings look like.** On exhaustion,
stop. Post everything on the ticket: every finding, every fix attempted, the taste verdict if one
ran. Leave the worktree and the branch standing and hand it to a human. An exhausted loop is a
finding, not an obstacle to work around, and a loop with no exit is how an unattended run burns a
budget and lands something nobody chose.

## Step 7: LAND, to `max_autonomy` and no further

Each route carries its own dial, and it is the only thing that changes to turn a capability on or
off for a project or a person:

- `"plan"` - investigate, post the plan on the ticket, stop.
- `"branch"` - fix, verify, commit, push. No PR.
- `"pr"` - fix, verify, commit, push, open a PR via the project's configured `pr.skill`.

Merging is not a level. There is no configuration that permits it.

Before the PR, `workflow:worktree` re-fetches the base and dry-runs the merge. A detected conflict
STOPS the run at that point, whatever the dial says.

## Step 8: ALWAYS report back ON THE TICKET

Every path out of this skill (success, plan-only, failing verify, an exhausted review loop, a taste
verdict, a conflict, missing config) ends with a comment on the ticket: what was done, the branch
name, the worktree path, the verify output as it actually ran, what each reviewer found and what was
done about it, and every judgment call the ticket did not settle.

Report to the ticket even when a human IS in the session, because the ticket is where the next
person looks and the session transcript is not. A run whose findings exist only in a terminal nobody
read has done the work and thrown away the result.
