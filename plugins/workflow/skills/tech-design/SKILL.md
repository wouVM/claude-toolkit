---
name: tech-design
description: >
  Turn a sharpened ticket (the WHAT) into a technical design (the HOW) before it is signed: options
  with trade-offs, a recommendation, a file-by-file shape, one-way doors, and the tests that prove
  it, posted on the ticket as a comment. Load it when a ticket touches more than one
  subsystem or ~8 files, adds or removes an external dependency, needs a data migration or changes
  a stored shape other code reads, changes a contract callers rely on (a shared function's
  meaning, an API response, a tool signature), or introduces a new long-lived concept (a model, a
  service, a scheduled job); or when the user says "/tech-design", "design this first", "how should we build this", "is this a
  scalpel or a bazooka". For anything else, skip it in one line and go on to signing and pickup. It
  never builds and never creates a worktree.
argument-hint: "<ticket>"
---

# /tech-design - decide the HOW before a builder invents it

ELI16 first: a ticket says what must be true. For most changes the how is obvious from the
codebase, and the ticket goes on to signing and the build. For some it is not, and building
without deciding first is how an agent quietly invents an architecture nobody chose. This skill is
the short stop for those tickets only. It runs before the ticket is signed, after
`workflow:ticket-format` (and its `workflow:spec-sharpen` pass) has ended with the ready check. It
posts the design as a ticket COMMENT, never a body edit: the ticket stays the contract, the ready
check stays the last description write and stays valid, and a technical detail in a ticket body
becomes a literal target that shields the outcome it was meant to serve.

## Scalpel or bazooka

A design is REQUIRED when ANY of these is true:

- more than one subsystem, or more than ~8 files
- an external dependency or integration is added or removed
- a data migration, or a change to a stored shape other code reads
- a change to a contract callers rely on (a shared function's meaning, an API response, a tool
  result shape or signature)
- a new long-lived concept: a model, a service, a scheduled job

Otherwise it is a scalpel change: say so in one line and skip the design, deliberately. The gate
only works if it stays cheap for the common case.

**Whoever finishes writing a ticket states its route** in a comment on it: scalpel and why,
design-first and which trigger fired, or the project's other route (for example a prompt or
configuration change). A ticket that reaches a build without that line is not ready, whatever its
status column says.

## Step 1: read the contract

The sharpened ticket: user story, requirements, acceptance criteria, out of scope, plus any review
file the project keeps for it. Where the project's docs already fix a shape (a signature, a module
name), build on it and say so rather than reopening it. If the acceptance criteria are vague
enough that two designs would both satisfy them, STOP and name the ambiguous criterion: that is a
spec defect, and `workflow:spec-sharpen` owns it.

## Step 2: one framing, by default

One agent (a fresh build-tier model, one continuous turn, no code) writes ONE framing: the
recommended approach, plus the strongest alternative in a paragraph with why it lost. It cites
`file:line` for every claim about how the code works today.

**Three framings only when earned.** If a fresh reviewer says the choice is not obvious, or the
change is a one-way door, dispatch three separate agents in one message: **minimal** (smallest
diff, maximum reuse, allowed to find that an existing mechanism already covers it), **clean** (the
concept modelled properly, and what else must change to stay consistent) and **pragmatic** (the
smallest change that does not paint you into a corner). Why not always three: on a real build,
three framings per design produced 32 files that nobody cited outside their own design.

Prefer reuse over new code. A design that duplicates something the codebase already has is
rejected.

## Step 3: write the design

- **Recommendation** first, in three sentences: which approach and the one reason it wins.
- **Options and trade-offs**: what each does, its size, what it costs, what it buys. A real
  trade-off, not a strawman; if framings converged, say so.
- **The shape**: file-by-file, what changes and why. The builder's allowlist is cut from this.
- **One-way doors**: the decisions that would be expensive to reverse, each a sentence a
  developer can disagree with.
- **How it lands**, when behaviour spans configuration or prompts and code: same PR, or which goes
  first. A prompt naming a tool argument the code does not offer yet, or code returning a field no
  prompt tells the model how to use, is the defect this line prevents.
- **Tests that prove it**, one per rule, at the layer where the rule is observable, including the
  one that fails today.
- **What I am least sure about**: the honest paragraph a reviewer should attack first.

Post the design on the ticket as a comment, with the recommendation in one line. No worktree
exists yet, so the ticket is where the design survives until the build commits it.

## Step 4: decide, then hand off

Technical choices are the coordinator's. Fresh reviewers who did not write the design judge it;
the coordinator picks and records why on the ticket. Only a BUSINESS question (what a user or
customer gets) goes to the human, batched, each with a recommended answer. Never send a
technical question up.

When picked, post the chosen design as one comment whose first line is `DESIGN (picked)`, with the
option and the one-line reason; only that comment is the spec, earlier framings and rejected
versions are not. On rejection, note
what was rejected and why, and revise.

After the pick, the ticket goes to the human to sign as usual. When `workflow:pickup` takes it,
the route's fix skill builds it with the design as part of the spec, and the builder commits the
design as `docs/tickets/<ticket>/design.md` with the change.

## What this skill must not do

- Write or modify code, or create a worktree.
- Put technical specification into the ticket body, or edit the body at all.
- Present one answer as if no alternative existed.
- Decide a business trade-off: name it and ask.
