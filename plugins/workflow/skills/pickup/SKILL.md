---
name: pickup
description: >
  Take a human-signed ticket off the tracker and carry it to an open PR without a person driving
  each step: poll for signed tickets, CLAIM one so a parallel run cannot take it, isolate a
  worktree, route by the ticket's diagnosis kind to the project's configured fix skill, run the
  project's verify command, put the diff through a bounded review loop with the project's own
  reviewers before it lands, and land only as far as that route's max_autonomy allows. Use when
  the user says "/pickup", "pick up the next ticket", "work the queue", "anything signed off
  yet", "take PROJ-123", "review it before the PR", "run the reviewers on this branch", or
  schedules an unattended run over a tracker. Bootstraps its own labels: a preflight proves the
  tracker accepts the configured labels and that the poll query is well-formed before any poll
  runs, so nobody has to hand-apply a label to a real ticket to conjure it. Reads its policy from
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

## The ticket carries the trail

The description is the contract: a change to scope or acceptance criteria is an EDIT to it, never a
comment. Comments are the record of how the run got there, and they are required, posted as each
thing happens rather than batched at the end: the claim (branch and worktree path), the verify
result, each review round (findings, what changed, the re-verify), behavioural checks run, the PR
link, and any stop with what a human must decide. A run that ends with no comments on its ticket is
a defect in the run, not a tidy ticket.

## Step 0: the config, or stop

Read `.claude/pickup.json` from the repo root. Everything policy-shaped lives there: the tracker and
its statuses, the repos and their base branches, the worktree root, the verify command, the
diagnosis kinds, the route per kind, the PR skill, and the `review` block (which reviewers to run,
which taste gate to escalate to, how many rounds are allowed), and `require_ready_check` (whether a
signed ticket without a passing ready check is refused, see Step 2). If the file is absent, print the
fields that would be needed and stop. Do not improvise a tracker query, a base branch, or a fix
path: this skill is identical in every project and only the config makes it correct in one.

## Step 1: PREFLIGHT the labels and the query

Before the first poll of a session, prove that `pickup_label` and `in_flight_label` are usable and
that the poll query built from them is well-formed. This runs once per session and is idempotent, and
it NEVER touches a ticket to achieve it.

What "ensure the label exists" means depends on the tracker, because trackers disagree about what a
label is.

In Jira a label is not a first-class object. It springs into the label pool the first time it is
applied to an issue and vanishes when the last issue drops it, so there is nothing to create and no
API that creates one. Ensuring it therefore means two checks that write nothing: confirm the tracker
will ACCEPT the label (the field exists on the project's issue type and the string is a legal label,
no spaces), and run the poll query itself to confirm it is well-formed and returns a result set. Zero
results is a valid answer and is exactly what proves the query works. Do NOT apply the label to some
unrelated ticket to bootstrap it into the pool: that would make that ticket pickup-eligible the
moment someone moves it, which is the workaround this preflight exists to remove.

Where the tracker DOES have first-class labels, create them idempotently. On GitHub that is the
`workflow:issue` pattern, `gh label create "<label>" --repo "$REPO" 2>/dev/null || true`, which
succeeds whether or not the label was already there.

If the preflight cannot run at all, because the tracker is unreachable, auth is missing, or the
project key resolves to nothing, STOP and say what is missing and what the human should do about it.
Never proceed to poll on a query you could not verify. A malformed or unmatched query returns zero
tickets, and zero tickets is indistinguishable from "no work to do": the run reports a clean no-op,
looks exactly like success, and does it again on every schedule. Silently doing nothing forever is
the worst failure this chain has, precisely because nobody is watching the session it happens in.

## Step 2: POLL (read-only)

Find candidates: in `signed_status`, carrying `pickup_label`, with no linked PR and without
`in_flight_label`. Shaped as JQL:

```
project = <KEY> AND status = "Ready for Dev" AND labels = "auto-fix"
  AND labels != "in-flight" AND issueFunction not in linkedIssuesOf("...")
```

Use the project's tracker MCP or CLI, and use the query the preflight already proved well-formed.
Take ONE ticket unless the user explicitly asked for more. Polling writes nothing, to the tracker or
the repo, so a poll that finds nothing is a clean no-op and a safe thing to run on a schedule, which
it only is because the preflight has already ruled out the other reason a query returns nothing.

**Signed is not enough: the ticket also needs a passing ready check.** Before claiming, read the
ticket's comments for the latest `READY CHECK` block that `spec-sharpen` posts, and parse only from
its `READY CHECK:` line to the first blank line. It passes only when the header says `pass` AND all
six keys (`testable-criteria`, `route`, `deploy-order`, `staging-limits`, `activation`,
`open-questions`) are present, each marked `[pass]` (in any order), and the blank line after them is followed by a non-empty `ELI5:` line. Anything else fails: no block, a `fail` header,
a missing or `[fail]` key, a missing ELI5, or a description edited after the block was posted. What happens then
depends on `require_ready_check`:

- `true`: do not claim. Post one comment, `Refused: no passing ready check. Failing: <each failing
  or missing key, or "no ready check on this ticket", or "description edited after the ready
  check">. Re-run spec-sharpen and sign again.`, then move to the next candidate.
- absent or `false`: post the same lines once as a warning (`Warning: no passing ready check.
  Failing: ...`) and proceed to the claim. This keeps projects that signed tickets before the ready
  check existed working; new projects get `true` from the setup template.

The refusal is the only write before a claim, and either comment is posted once: a later poll that
finds the same comment on an unchanged ticket does not post it again. Read the trail comment, never
re-run the sharpening here. Why: the signature says a human agreed, the ready check says there was
something complete to agree to, and an unattended run that sharpens its own ticket is signing it on
the human's behalf.

## Step 3: CLAIM, before any work

Add `in_flight_label` and, if `in_progress_status` is configured, transition the ticket. Only then
start.

The order is the whole point. Two scheduled runs, or a scheduled run and a person, can poll the same
queue seconds apart; if the claim happens after the work, both do the work and one of them discovers
it at push time, having burned a full run. The label is a cheap lock in a place both runs can see.
If the claim write fails, stop: an unclaimed ticket is not yours.

## Step 4: ISOLATE

Create the worktree with `workflow:worktree`, in the sub-repo the ticket touches, branched from that
repo's freshly fetched `base`. That skill owns the isolation and conflict discipline; do not
hand-roll a `git checkout` here.

## Step 5: ROUTE by diagnosis kind

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

## Step 6: VERIFY

Run the project's `verify` command, exactly as configured, and read the real output.

**A failing suite is a finding, not an obstacle.** Stop, post the failure output on the ticket, leave
the worktree in place, and do not try to make it green by weakening a test. A red suite on a fix is
information: either the fix is wrong, or the suite pins something the ticket did not account for.
Both are things a human needs to see, and both are destroyed by a run that quietly adjusts the
assertion.

## Step 7: REVIEW, in a loop that is allowed to end badly

This step runs when the route's `max_autonomy` is `branch` or `pr`. A `plan` route produced no diff,
so there is nothing to review and the loop is skipped. If `.claude/pickup.json` has no `review`
block, skip the loop too and SAY SO in the report: a project with no configured reviewers has none,
and inventing one is worse than naming the gap.

**Dispatch every reviewer in `review.reviewers` IN PARALLEL, in one message.** Each gets the commit
range and reads the repo itself; none is ever handed pasted code. Each brief also names, by name,
the existing rules and contracts the change touches or could contradict (the exception next to the
new rule, the caller that relies on the old meaning), and asks for each whether the new rule and
the old one can both hold. A reviewer who is never told about the neighbour reviews the new rule
alone and passes a contradiction. A configured reviewer is a skill
the project has (`codex review`, `gemini review`) or this plugin's `reviewer` agent, and reviewers
are always dispatched fresh, never the agent that wrote the code. The builder does not review itself,
including when the builder is the thing that just fixed a reviewer's finding.

**A single VERIFIED defect blocks, and a majority does not clear one.** If any reviewer reports a
P0 or P1 it can ground in a file, the work goes back to the route's fix skill with that defect as its
input, and the verify command runs again afterwards: a fix that breaks the suite is worse than the
defect it repaired. Never weaken or delete a test to clear a finding. That destroys the exact
information this run exists to produce.

**Fix by class, not by line.** A finding is a sample of a defect class. Grep the codebase for the
class and fix every instance in one pass. If round N+1 raises the same class as round N, a line was
fixed instead of the class.

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

## Step 8: LAND, to `max_autonomy` and no further

Each route carries its own dial, and it is the only thing that changes to turn a capability on or
off for a project or a person:

- `"plan"` - investigate, post the plan on the ticket, stop.
- `"branch"` - fix, verify, commit, push. No PR.
- `"pr"` - fix, verify, commit, push, open a PR via the project's configured `pr.skill`.

The PR description is written for the reviewer, from `templates/pr-description.md` next to this
SKILL.md, and the first reviewer may not be a developer. It opens with four plain sections: Why (the
user or business problem), What changes (for each group the change reaches), How it was tested
(including what could not be, and why), and Review in this order (one "Check:" line per item,
highest risk first). The technical sections (Size, Deploy, Verification, Not in this PR) follow
under Details. The title is `[<ticket>] - <plain description>`, never the branch name. Every number
in it comes from `pr_test_stats.py` (shipped with `workflow:test-writing`) as it printed; never
estimate one. When
`pr.skill` has its own template, that template wins and these sections go into it.

If the host's API answers 401 or 403, confirm with ONE direct API call that the credential is what
failed (the project's `tools-check.sh`, where `workflow:project-setup` seeded one, does this and
also catches a malformed value before you blame the token), then push over SSH and hand the human the prefilled create-PR URL plus the description file.
Never retry the same call hoping: a stale credential does not heal between attempts.

Merging is not a level. There is no configuration that permits it.

Before the PR, `workflow:worktree` re-fetches the base and dry-runs the merge. A detected conflict
STOPS the run at that point, whatever the dial says.

## Step 9: ALWAYS report back ON THE TICKET

Every path out of this skill (success, plan-only, failing verify, an exhausted review loop, a taste
verdict, a conflict, missing config) ends with a comment on the ticket: what was done, the branch
name, the worktree path, the verify output as it actually ran, what each reviewer found and what was
done about it, and every judgment call the ticket did not settle.

Report to the ticket even when a human IS in the session, because the ticket is where the next
person looks and the session transcript is not. A run whose findings exist only in a terminal nobody
read has done the work and thrown away the result.
