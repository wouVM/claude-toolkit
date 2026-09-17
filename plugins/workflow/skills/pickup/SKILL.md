---
name: pickup
description: >
  Take a human-signed ticket off the tracker and carry it to an open PR without a person driving
  each step: poll for signed tickets, CLAIM one so a parallel run cannot take it, isolate a
  worktree, route by the ticket's diagnosis kind to the project's configured fix skill, run the
  project's verify command, and land only as far as that route's max_autonomy allows. Use when
  the user says "/pickup", "pick up the next ticket", "work the queue", "anything signed off
  yet", "take FB-123", or schedules an unattended run over a tracker. Reads its policy from
  .claude/pickup.json and stops with an explanation if that file is absent. It NEVER merges,
  never resolves a conflict, and never signs a ticket itself (that is the human's act, and the
  ticket half is workflow:intake).
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, AskUserQuestion, Skill
---

# /pickup - a signed ticket becomes a branch, and reports back

ELI16 first: the tracker is the queue and a human's signature is the go-ahead. This skill reads the
queue, takes exactly one ticket, marks it taken so another run cannot grab the same one, does the
work in its own isolated copy of the repo, runs the tests, and pushes as far as the project's dial
says it may. Everything it learns goes back ONTO THE TICKET, because by construction nobody is
watching the session it runs in.

## Step 0: the config, or stop

Read `.claude/pickup.json` from the repo root. Everything policy-shaped lives there: the tracker and
its statuses, the repos and their base branches, the worktree root, the verify command, the
diagnosis kinds, the route per kind, and the PR skill. If it is absent, print the fields that would
be needed and stop. Do not improvise a tracker query, a base branch, or a fix path: this skill is
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

## Step 6: LAND, to `max_autonomy` and no further

Each route carries its own dial, and it is the only thing that changes to turn a capability on or
off for a project or a person:

- `"plan"` - investigate, post the plan on the ticket, stop.
- `"branch"` - fix, verify, commit, push. No PR.
- `"pr"` - fix, verify, commit, push, open a PR via the project's configured `pr.skill`.

Merging is not a level. There is no configuration that permits it.

Before the PR, `workflow:worktree` re-fetches the base and dry-runs the merge. A detected conflict
STOPS the run at that point, whatever the dial says.

## Step 7: ALWAYS report back ON THE TICKET

Every path out of this skill (success, plan-only, failing verify, conflict, missing config) ends with
a comment on the ticket: what was done, the branch name, the worktree path, the verify output as it
actually ran, and every judgment call the ticket did not settle.

Report to the ticket even when a human IS in the session, because the ticket is where the next
person looks and the session transcript is not. A run whose findings exist only in a terminal nobody
read has done the work and thrown away the result.
