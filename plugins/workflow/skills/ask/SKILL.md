---
name: ask
description: >
  Answer a question about the system, or talk through a requirement, grounded in the real thing:
  the code, a read-only production query, the logs, the tracker and a third party's own API, with
  every present-tense claim citing its proof and the time it was checked. Checks what already
  ships (open and recently closed tickets, the code) BEFORE recommending anything, because "can we
  do X" often means "does X work yet". Answers only: no edits, no tickets, no production writes,
  and it ends by offering the next step, usually workflow:intake. Use when someone asks "does X
  work", "why does the bot / app do Y", "can we do Z", "what would it take to", "is this already
  a ticket", "did we ever fix", "how does X decide", or wants to discuss requirements before
  anything is written down. NOT for an explicit build or change request ("fix it", "implement",
  "change the prompt"), NOT for turning a request into a ticket (workflow:intake), and NOT for
  reading one long document (workflow:digest).
allowed-tools: Read, Glob, Grep, Bash, Agent, AskUserQuestion, Skill
---

# /ask - answer from the system, not from the question

ELI16 first: a product manager asks "can we send guests a reminder when their table is ready?". The
fastest answer is a confident plan for building it. The right answer might be "that shipped in May,
it is switched off for two venues, here is the setting". The question's wording carries a guess
about the system, and answering the wording repeats the guess. This skill looks first: the tracker,
the code, the live data. Then it answers in a few lines, each one with its proof and when it was
checked, and stops. Nothing gets built or filed until the person asking says so.

## Step 0: is this a question?

Run this skill when the message asks something or explores a requirement. If it is an explicit
instruction to change something ("fix", "build", "implement", "change the prompt", "go ahead"),
this is the wrong skill: hand over to the project's build or change flow. If it is a pasted request
that should become work ("a client reported X, write it up"), that is `workflow:intake`.

When unsure, treat it as a question. Why: a question answered is cheap to turn into work, and work
started on a question is an edit nobody approved.

## Step 1: pin the question down

Restate in one line what is being asked and what a complete answer looks like: yes or no, a
mechanism, a list of places, a size. If two readings are plausible and they lead to different
evidence, ask once (AskUserQuestion), offering both readings. Otherwise pick the likelier one and
say which you picked.

Name the subject in the system's terms: the feature, the integration, the tenant or account, the
screen, the date range. These are the search terms for every step below.

## Step 2: check what already ships, before any recommendation

Two searches, always, before the answer takes shape:

- **The tracker**: open tickets on the CAPABILITY, not only on the requester's words, and tickets
  closed within the project's window (`relations.closed_window_days` in `.claude/pickup.json`,
  default 180). A closed ticket's description is the best record of what shipped and what was
  deliberately left open; read it rather than guessing from its title.
- **The code**: does the capability, a flag for it, or half of it already exist?

Why: "can we do X" often means "does X work yet", and a recommendation to build something that
shipped last month wastes a design and tells the requester we do not know our own system. The same
search also answers "is this already a ticket" and "didn't we fix this".

If the tracker is not reachable, say so in the answer ("tracker not searched: <reason>"). Never
answer as if the search came back empty.

## Step 3: gather evidence, on the cheap model

Dispatch this plugin's `explorer` agent (read-only, cheap model) for anything wider than two or
three files: tracing a behaviour, finding every place a rule lives, reading a ticket history. Run
independent scouts in parallel in one message. Give each a named scope, the question, and this
instruction: every claim about how the system behaves TODAY comes back with a `file:line`, a ticket
key or a quoted log line; a claim it cannot cite comes back as an open question.

The main thread then opens the cited lines that the answer rests on and checks them. Why: a scout's
report is evidence, not truth, and "nothing in the code handles X" is the claim most worth a second
look, because a scout that missed a directory writes the same sentence as one that read it all.

Sources, by what they can prove:

- **Code** proves what the system is built to do: `file:line`, on a checkout you have confirmed is
  current (fetch first; a stale branch answers for last month).
- **Production data** proves what it actually did: read-only queries only, through the recipe in
  the project's `CLAUDE.md` (or its runbook). If the project gives no read-only path, say the claim
  is unverified against production; never borrow a read-write credential to check it.
- **Logs** prove what happened on one occasion: quote the line with its timestamp.
- **The tracker** proves what was decided and when: the ticket key and its status.
- **A third party's own docs or API** prove what that party can do. Our code comment about a
  supplier is hearsay with a date on it: probe a public read endpoint, or read their current docs,
  before saying "they cannot do X". A write call with a deliberately invalid identifier shows which
  payloads are accepted without touching real data; anything riskier is the human's call.

What cannot be checked is marked `unverified`, with what would verify it. Why: an unmarked guess
reads exactly like a checked fact, and the next person builds on it.

## Step 4: answer short

Lead with the answer. A yes/no question gets yes or no as its first word, or "partly" followed by
the split. Then one line per finding, each carrying its proof and when it was checked:

> Yes, it already ships, switched off for two venues.
> - Reminder job exists and runs hourly (`reminders/tasks.py:41`, checked 2026-09-25 10:12).
> - Enabled for 14 of 16 venues (prod query on `venue_settings`, 2026-09-25 10:15).
> - Built under PROJ-412, Done 2026-05-03; "same-day bookings" left open in its description.
> - Unverified: whether venue B turned it off on purpose (ask the account owner).

No process narration: not which agents ran, not how many files were read. Sparse formatting, no
tables unless the data is a table. If the answer needs more than a screen, the detail goes into a
file, and only when the person asks for one.

Dates and times are absolute (`2026-09-25 10:12`), never "today". Why: an answer gets pasted into a
ticket or a chat, and a claim with no time on it looks current forever.

## Requirements discussion mode

When the conversation is shaping something new rather than asking about something existing, keep
the same grounding and add four things to the answer:

- **Seen versus inferred.** What the requester observed ("guests arrive to a full room") apart from
  what they concluded ("the booking limit is wrong"). The inference is usually the part that is
  wrong, and it is the part a builder will treat as the brief.
- **What the system does today** on this point, cited, so the requirement changes something real.
- **Open questions that block a ticket**, each one a sentence a person can answer, with the person
  or role who owns the answer (the client, the account owner, the developer who owns the area).
- **Never invent a stakeholder's answer.** A business rule, a price, a policy or a priority that
  nobody has stated stays an open question, however obvious it seems. Proposing a default is fine
  when it is labelled as a proposal for that person to confirm.

Carry the running state across turns: decided (by whom), still open, and the evidence behind each.

## Step 5: offer the next step

End with one line offering what comes next, matched to where the conversation landed:

- The discussion converged on something to build or fix: "Turn this into a ticket?" On yes, run
  `workflow:intake` with this discussion as its source (the question, the seen/inferred split, the
  cited findings, the open questions and their owners), so the relation scan and spec-sharpen run
  on it instead of on a paraphrase.
- It matched an existing ticket: offer to add the new evidence to that ticket, via intake's
  duplicate path.
- It is a regression of a closed ticket: say so, name the ticket, offer intake.
- It is answered and nothing needs doing: say that, and stop.

Offer; do not start. Why: the person asking decides whether a question becomes work, and a skill
that files its own tickets turns every question into backlog.

## Rules

- Answer only. No edits to code, prompts, config or docs; no tickets or tracker comments; no
  production writes of any kind (queries that change rows, enqueued jobs, admin changes). A
  requested change is reported as "what would need doing" and left to the person who owns it.
- Never print credentials, tokens, connection strings or personal data from production (guest
  names, phone numbers, e-mail addresses, message text). Report counts, ids and shapes instead;
  quote a message only with the personal details masked.
- Never recommend building something before Step 2 has run.
- A present-tense claim without proof is either verified now or labelled `unverified`.
- Do not re-explain a cause the person has already acknowledged.
