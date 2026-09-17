---
name: intake
description: >
  Turn an incoming request (a pasted email, a forwarded complaint, a file, a Gmail label) into
  one diagnosed, evidence-cited, sharpened ticket filed in the tracker as a DRAFT for a human
  to sign. Separates the reporter's SYMPTOM from their INFERENCE, dispatches a grounded
  investigation that must cite file:line for every claim about how the system behaves today,
  scans the tracker for what the request already relates to (a duplicate of an open ticket, or a
  REGRESSION of a closed one), then runs spec-sharpen and files. Use when the user says
  "/intake", "turn this email into a ticket", "file this complaint", "a client reported X, write
  it up", "triage this request", "did anyone already report this?", "is this a known issue",
  "didn't we fix this already", or pastes a customer message expecting work to come out of it.
  NOT for writing a ticket the
  user has already diagnosed (file that yourself), NOT for picking up a signed ticket (that is
  workflow:pickup), and it never signs off its own ticket.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, AskUserQuestion, Skill
---

# /intake - a request becomes a diagnosed ticket, not a transcription

ELI16 first: someone emails you "the bot can't book appointments". That sentence contains two
different things glued together: what they SAW (no appointment got booked) and what they THINK is
wrong (the bot is broken). Writing a ticket that repeats the glued sentence hands the wrong problem
to whoever picks it up. This skill pulls the two apart, sends a cheap agent to find out what the
system actually does today with line numbers to prove it, checks whether the tracker already holds
this thing (or once held it and closed it), and files a draft ticket that a human can falsify in one
read. The human signs it. The signature is the only thing that authorises work.

## Step 0: the config

Read `.claude/pickup.json` from the repo root. It names the tracker, the project key, the draft and
signed statuses, the labels, the `diagnosis_kinds` this project routes on, and the `relations` block
(how far back to look for closed tickets, and the project's regression marker). If the file is
absent, say exactly which fields you would need and stop: guessing a tracker project key files a
ticket into somebody else's board, and inventing a diagnosis kind produces a verdict that
`workflow:pickup` cannot route.

## Step 1: symptom versus inference

Restate the request as two separate lists, in the requester's own words where you can.

- **Symptom**: what they observed. "No confirmation email arrived." "It answered in English."
- **Inference**: what they concluded caused it. "The prompt is wrong." "The integration is down."

Clients conflate these and so do colleagues, because a guess said confidently sounds like a report.
The separation matters because the inference is the part that is usually wrong, and it is also the
part that a downstream agent will treat as the brief. Keep both in the ticket: the inference is
real evidence about what the requester expected, it is just not evidence about the code.

If the symptom is not recoverable from the message (no example, no timestamp, no account), that is a
finding, not a blocker. Note it and say so in the report, or ask the requester once via
AskUserQuestion if the whole ticket hinges on it.

## Step 2: diagnose with evidence (this is the step that earns the chain)

Dispatch a read-only investigation with this plugin's `explorer` agent, on a cheap model. Give it
the symptom, the inference, and an explicit instruction: every claim about how the system behaves
TODAY comes back with a `file:line` citation, and a claim it cannot cite gets reported as an open
question rather than stated.

It returns a verdict of one of the project's configured `diagnosis_kinds` (a common default set is
`code`, `config`, `unknown`), plus the evidence.

This step is why the whole chain is allowed to run without a human in each loop. Every lens
downstream (the sharpener, the picker-upper, the fix skill, the reviewer) sees only the TICKET BODY.
A false premise about current behaviour is therefore invisible to all of them: it is not contradicted
by anything they can read, so it survives intact into the diff and gets defended in review. The
citation is the one cheap thing that stops it, and it only works if it is enforced here, before the
ticket exists.

`unknown` is a legitimate verdict and a useful one. A ticket that honestly says "we could not
determine which layer owns this" routes to a human; a ticket that guesses `code` routes to a builder
who will then make the guess true.

## Step 3: scan the tracker for what this already relates to

The diagnosis hands you the words worth searching, and there is no point drafting a ticket that
should have been a comment on one that exists. Query the tracker twice, bounded, using the salient
nouns from the request and the diagnosis: OPEN tickets in the project, and CLOSED tickets within
`relations.closed_window_days` (default 180). If the project has its own issue or ticket skill that
already scours relations (`workflow:issue` does), let it own the OPEN half rather than duplicating
its logic, and run the CLOSED half here, which it does not cover.

Then read the candidates and decide the relation IN CONTEXT, as ONE verdict rather than prose that
hedges:

- **duplicate** of an OPEN ticket: the same item already exists. Do NOT file. Propose amending that
  ticket with the new evidence instead (a second reporter, a new symptom, a fresh occurrence).
- **regression-of** a CLOSED ticket: the request matches something already fixed and closed. File a
  NEW ticket, link the closed one explicitly, and say in the body that this is a recurrence of
  `<ref>`, closed on `<date>`. Where the project's conventions carry a regression marker
  (`relations.regression_label`, or a field), apply it.
- **related** to one or more tickets: overlapping, distinct. File and cross-link.
- **sub-issue** of an open ticket: a concrete piece of a larger existing item.
- **new**: nothing meaningfully connected.

The regression case is the one a plain duplicate check misses, because a duplicate check only ever
looks at open tickets, and it is the most valuable verdict here. A regression is a DIFFERENT and more
urgent thing than a new bug: something that was verified working is broken again. It also arrives
with an inheritance, because the original ticket carries the fix, the test that was supposed to pin
it, and the reasoning about why that was the right fix. A ticket filed as a fresh bug throws all of
that away and pays for it twice.

Be conservative on every verdict: claim only a relation a human would agree with at a glance, and
judge on meaning, never on shared words. Present it TIGHT (the ref, a short title, half a line of
why), then confirm before filing unless the caller passed a skip-confirm flag. Filing is outward and
sticky, so this confirm doubles as the post gate.

If `.claude/pickup.json` has no `relations` block, scan the open tickets and, where the tracker makes
it cheap, the closed ones on the same default window. A missing optional block never fails the run.

## Step 4: draft it in the project's house style

If the project has its own ticket-writing skill (`jira-ticket-writing`, a house template, a
CONTRIBUTING section), USE IT and let it own the format. This skill orchestrates; it does not
impose a second house style on top of an existing one. Only when no such skill exists do you write
the body yourself: symptom, inference, diagnosis verdict, the cited premises, acceptance criteria
that someone who never reads the diff could check.

Put the PREMISES at the top, as a short list with their citations. A human who knows the system can
then falsify the ticket in one read, which is the cheapest review available anywhere in this chain.

## Step 5: sharpen

Run `workflow:spec-sharpen` on the draft. Match intensity to stakes as that skill says: a two-line
bug report gets the combined lens and the premise reconcile, not four rounds. Fold its DECIDEs in,
write its DEFERs into the ticket body, and keep its sidecar review file out of the ticket.

## Step 6: file as DRAFT

File into the tracker in the project's configured draft or triage status, with `pickup_label` if the
project wants the ticket to be pickup-eligible once signed. Attach the diagnosis verdict in whatever
field the project routes on (a label, a custom field, or a line in the body that pickup can read).

**Never transition the ticket to the signed status.** That transition is the human's act, it is the
only authorisation `workflow:pickup` recognises, and a skill that could both file and sign would
make the signature decorative. It is also reversible and visible to the team, which is exactly what
an authorisation should be.

## Step 7: report

Report the ticket ref, the diagnosis verdict and why, the relation verdict and the tickets it names,
the premises with their citations, and, as its own section, what the investigation could NOT
determine. The last one is the part a reader will act
on, so do not bury it.
