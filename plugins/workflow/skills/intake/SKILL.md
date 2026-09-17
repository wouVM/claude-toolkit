---
name: intake
description: >
  Turn an incoming request (a pasted email, a forwarded complaint, a file, a Gmail label) into
  one diagnosed, evidence-cited, sharpened ticket filed in the tracker as a DRAFT for a human
  to sign. Separates the reporter's SYMPTOM from their INFERENCE, dispatches a grounded
  investigation that must cite file:line for every claim about how the system behaves today,
  then runs spec-sharpen and files. Use when the user says "/intake", "turn this email into a
  ticket", "file this complaint", "a client reported X, write it up", "triage this request",
  or pastes a customer message expecting work to come out of it. NOT for writing a ticket the
  user has already diagnosed (file that yourself), NOT for picking up a signed ticket (that is
  workflow:pickup), and it never signs off its own ticket.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, AskUserQuestion, Skill
---

# /intake - a request becomes a diagnosed ticket, not a transcription

ELI16 first: someone emails you "the bot can't book appointments". That sentence contains two
different things glued together: what they SAW (no appointment got booked) and what they THINK is
wrong (the bot is broken). Writing a ticket that repeats the glued sentence hands the wrong problem
to whoever picks it up. This skill pulls the two apart, sends a cheap agent to find out what the
system actually does today with line numbers to prove it, and files a draft ticket that a human can
falsify in one read. The human signs it. The signature is the only thing that authorises work.

## Step 0: the config

Read `.claude/pickup.json` from the repo root. It names the tracker, the project key, the draft and
signed statuses, the labels, and the `diagnosis_kinds` this project routes on. If the file is
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

## Step 3: draft it in the project's house style

If the project has its own ticket-writing skill (`jira-ticket-writing`, a house template, a
CONTRIBUTING section), USE IT and let it own the format. This skill orchestrates; it does not
impose a second house style on top of an existing one. Only when no such skill exists do you write
the body yourself: symptom, inference, diagnosis verdict, the cited premises, acceptance criteria
that someone who never reads the diff could check.

Put the PREMISES at the top, as a short list with their citations. A human who knows the system can
then falsify the ticket in one read, which is the cheapest review available anywhere in this chain.

## Step 4: sharpen

Run `workflow:spec-sharpen` on the draft. Match intensity to stakes as that skill says: a two-line
bug report gets the combined lens and the premise reconcile, not four rounds. Fold its DECIDEs in,
write its DEFERs into the ticket body, and keep its sidecar review file out of the ticket.

## Step 5: file as DRAFT

File into the tracker in the project's configured draft or triage status, with `pickup_label` if the
project wants the ticket to be pickup-eligible once signed. Attach the diagnosis verdict in whatever
field the project routes on (a label, a custom field, or a line in the body that pickup can read).

**Never transition the ticket to the signed status.** That transition is the human's act, it is the
only authorisation `workflow:pickup` recognises, and a skill that could both file and sign would
make the signature decorative. It is also reversible and visible to the team, which is exactly what
an authorisation should be.

## Step 6: report

Report the ticket ref, the diagnosis verdict and why, the premises with their citations, and, as its
own section, what the investigation could NOT determine. The last one is the part a reader will act
on, so do not bury it.
