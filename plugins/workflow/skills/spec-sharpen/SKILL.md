---
name: spec-sharpen
description: >
  Sharpen a spec, ticket, issue, or requirements doc through independent multi-pass review until it
  is SIGNABLE: a fresh-agent TPM lens, a blind lens that never sees the draft, a code-grounded dev
  lens, a cold exhaust pass, and a premise reconcile (every present-tense claim about current
  behaviour gets a file:line citation or is reworded out), five ranked findings per lens,
  DECIDE/DEFER/KILL triage, a convergence stop rule, then a ready check and a plain explanation for
  the signer. Leaves one comment per lens on the ticket so deferred or killed findings stay
  reviewable. Works on Jira (Atlassian MCP), GitHub issues (gh), or a markdown spec. Use when the
  user says "sharpen this spec/ticket", "are these requirements complete", "make this signable",
  "spec-driven", or before handing a non-trivial spec to a builder. NOT for reviewing code.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, AskUserQuestion
---

# /spec-sharpen - multi-pass requirements review until signable

A drafted spec is step one, not done. The build inherits every ambiguity, false premise, and
undecided question the spec carries, at 10x the cost. So the spec gets the same review rigor
a diff gets: independent lenses, adversarial passes, and a convergence rule.

**Fresh agents are the mechanism.** A model defends the reasoning it just produced; a cold one
argues with it. Never run a lens inside the context that drafted the spec. You (the
orchestrator) own the end result and make the edits; each lens is a fresh agent dispatched
via the Agent tool with the spec BODY only, never the drafting conversation (the blind lens gets
even less: the raw request only).

## Step 0: Locate the spec and its home

The spec lives where the team tracks work; read it from there and write it back there:
- **Jira ticket**: `getJiraIssue` via the Atlassian MCP (if connected).
- **GitHub issue**: `gh issue view N --json title,body`.
- **Markdown file**: read the path the user names.

The review record (premises, findings, triage fates, mechanism notes for the developer) goes
to a sidecar file next to the project's docs (e.g. `docs/<ref>-review.md`), NEVER into the
spec itself, and where the spec is a ticket the same record posts as comments on it. The
`lens_trail` block in `.claude/pickup.json` configures both: `post_comments` (default: post,
where a ticket exists) and `sidecar` (the path pattern for the review file). A project whose
tracker is noisy sets `post_comments: false` and keeps everything in the sidecar and the report.
Where the config sets `premises_location: "sidecar"`, the premises live at the top of the sidecar, not the body: give every lens except the blind one that premise block along with the body.

Before rewriting a ticket, read its status and history. A ticket already done or in progress means
the instruction to rewrite it rests on a stale premise: stop and confirm before overwriting anything.

## The trail: the reasoning belongs where the ticket is

Post the trail once, at the end of the run, when the spec is a ticket and the tracker supports
comments. Use the tracker's own comment API through whatever MCP or CLI the project has
(`addCommentToJiraIssue`, `gh issue comment`); this skill orchestrates and does not build a
tracker client.

**One comment per lens** (TPM, blind, dev, exhaust), naming the lens and listing each finding with
its fate. A `DECIDE` gets one line saying where it landed in the body. A `DEFER` gets its reason
and the condition that would reopen it. A `KILL` gets why it was noise.

The DEFER and KILL entries are the load-bearing ones. A DECIDE is already visible in the ticket
body, so a comment about it mostly repeats the spec, but a dismissal that leaves no trace is
exactly how a real finding gets lost: the exhaust pass raises a false premise, triage calls it
non-material, and three weeks later nobody can tell it was ever considered. A dismissal recorded
with its reason stays reviewable by the person who turns out to have been right.

**One comment for the premise reconcile**, listing every present-tense claim the ticket makes
about how the system behaves today, each with its `file:line` citation. This is the comment a
human who knows the system can falsify in one read, which is the cheapest check available
anywhere on the ticket.

**One comment for the ready check and the ELI5**, the last thing posted before the ticket is
offered for signing (both are described below).

**A final comment only if the loop ended without converging**, saying what is still open and why
it stopped.

Write for a human skimming a ticket, not as a dump: terse, one finding per line where it fits, no
restating what the body already says. A lens that found nothing gets a one-line comment saying so
rather than no comment at all, because "no findings" is information and a missing comment is
ambiguous between "clean" and "did not run". Post ONCE per sharpening run, and let a re-run add a
new set rather than editing the old one: an edited trail is not a trail.

No ticket to post to, which is the case for a spec file or a plain markdown doc, means the trail
goes in the report and, where the project keeps one, the sidecar review file. Never invent a
ticket to hold it.

## The hard rule: outcomes, never mechanisms

Requirements state WHAT must be observably true, in product terms. No endpoint shapes, HTTP
verbs, model/field designs, queue names, settings keys, or file paths - anywhere in the spec,
including as "hints". A spec detail becomes both a literal implementation target AND a shield
against the real business outcome ("but the ticket said GET /r/{token}"). Express constraints
as observable outcomes ("two venues must never share a URL segment", not "add a unique
constraint on name"). Genuinely useful implementation knowledge goes in the sidecar review
file or the PR, never the spec. This rule fully applies to lens findings when you fold them in.

**The rule binds the BODY, not a comment, and that is not a contradiction to be tidied away in
either direction.** It binds the body because a spec detail written there becomes a literal
implementation target AND a shield against the real outcome: an AC that read "wrapped in
GET /r/{token}" got implemented verbatim and then quoted back to deflect criticism. A comment is
discussion, not the contract, so a lens finding posted as a comment MAY name mechanism where
naming it is the clearest way to state the finding. What the two halves share is one direction of
travel: a mechanism detail may never migrate out of a comment and into an acceptance criterion.
When you fold a comment's finding into the body, restate it as the observable outcome it implies
and leave the mechanism behind in the comment.

## The lens contract: five findings, ranked

Every lens brief ends with this contract, word for word:

> Return at most FIVE findings, ranked by "would a user, a client or an end customer notice this
> if it shipped as written?", most noticeable first, each with one line of why. Anything below the
> fifth is dropped, not appended as "minor".

Why: a lens that returns fifteen findings buries the one that matters, and the human signing starts
deleting lines instead of reading them. The cap loses nothing that counts: the stop rule re-runs the
passes, so a real finding below the cut comes back once the ones above it are decided. The premise
reconcile and the ready check are not lenses and are not capped, because they are complete lists by
design.

## Round 1 - TPM lens (fresh agent) · `lens-tpm`

Give the agent the spec body only, and this lens:
- Scope boundaries: what is explicitly out? Any requirement claimed both in and out?
- Edge cases: named now, not discovered mid-build.
- Compliance exposure: what data, whose, logged where, deleted how?
- Acceptance criteria: verifiable by someone who never reads the code - an observable
  surface (a screen, a column, an export) must exist for every AC.
- "What does this spec not decide?"

Bar: **could this be signed off without reading the diff?**

## Round 1b - Blind lens (fresh agent, never sees the draft) · `lens-blind`

Dispatch it in the same message as Round 1, once per sharpening run. Give it ONLY the raw request:
the reporter's own words and evidence as intake captured them, never our draft or our title. Ask it
to write the ticket it would write: outcomes and acceptance criteria, under the same outcomes-only
rule as the body.

Then you diff the two, item by item. Every outcome, criterion, edge case or constraint present in
one and absent from the other is a candidate omission: one only the blind ticket has may be a thing
our draft never framed, one only our draft has may be a thing nobody asked for. Rank the candidates
by the lens contract, keep five, and triage them like any finding.

Why: every other lens reads our draft, so they all inherit its framing. The blind lens is the only
one that can notice the thing the draft never framed.

If there is no raw request apart from the draft (the spec was written from scratch), do not run the
blind lens; post its trail line as `blind lens: skipped, no raw request apart from the draft`. A
blind lens fed the draft is just another TPM lens.

## Round 2 - Dev lens (fresh agent, code-grounded) · `lens-dev`

FIRST dispatch a read-only code scan (this plugin's `explorer` agent) for the facts the lens
needs: the models and paths touched, existing flags and options, migration surface,
deletion/anonymization paths. THEN a fresh agent applies, with the scan results attached:
- Failure modes: what breaks, and how loudly?
- Blast radius: which other features touch these models or paths?
- Migrations: which, in what order, what is the rollback?
- Safeguards and observability: how would we know it went wrong? Every claim needs a
  verifiable number or surface.
- "What will I discover mid-build?" Surface it now.
- "What would an autonomous builder get wrong, and which guardrail catches it?" A missing
  guardrail is itself a finding.

Bar: **could a builder execute this without coming back with questions?**

## Round 3 - Exhaust (fresh agent, cold) · `lens-exhaust`

A fresh agent that has seen NONE of the prior rounds gets the CURRENT spec body and exactly
this prompt:

> "Enumerate everything this doesn't decide and every way it can break. Keep going until
> exhausted; organize by category."

followed by the lens contract. It searches until exhausted and returns the five that rank highest.

## Round 4 - Premise reconcile (you, the orchestrator - NOT an agent) · `premise-reconcile`

The lenses' blind spot: they are given the spec body only, so **a false claim about how the
system works today passes all of them unchallenged**. Round 2 sees code, but it is asked what
will break during the build, not whether the spec's description of current behavior is true.
Nobody owns that unless you do. Mechanically:

1. Extract every sentence asserting present-tense system behavior ("today the user gets X",
   "this is currently produced by Z").
2. Give each a `file:line` citation from the code scan. No citation means it is a guess:
   verify it or reword it out.
3. List the premises at the top of the sidecar review file, and in the premise comment on the
   ticket, so a human who knows the system can falsify them in one read - the cheapest check
   available; make it easy.

A claim about what an EXTERNAL system can or cannot do is verified against that system (its API or
its docs), not against a comment in our code: that comment is hearsay. Re-probe anything a supplier
called "planned" once the claim is older than a release cycle.

Treat as **material, never triaged away on a body-only reading**, any finding of the form
"which layer does this behavior actually live in?" or "this AC assumes X is config-driven /
code-driven and that is unstated." A spec has shipped a whole rollout justified entirely by
a false premise that an exhaust pass HAD flagged and triage dismissed.

## Triage - every finding gets exactly one of three fates

- **DECIDE now**: resolve it and write the outcome into the spec.
- **DEFER**: with a one-line reason, stated in the spec (usually Out of scope), and with the
  condition that would reopen it recorded in the lens comment.
- **KILL**: noise, dropped from the spec, with why it was noise recorded in the lens comment.

Every fate is recorded in the trail, which is what makes the triage itself reviewable. A fate
assigned in a session nobody reads is a decision nobody can check.

Where a DECIDE needs the user (a genuine stakeholder call), batch the questions and ask once
via AskUserQuestion; an unresolved stakeholder question is a BLOCKER, not a footnote - either
get the answer or write the chosen default into the spec with its rationale ("err on X
because Y") so the spec is signable either way.

## Stop rule

Done when **two consecutive further passes change no decision** AND the premise reconcile is
clean: re-run the exhaust prompt on the updated spec; if two passes in a row produce only
DEFER/KILL fates and zero new DECIDEs, and every present-tense claim carries a citation, the
spec goes to the ready check. Re-run the reconcile after ANY late edit - edits made after
convergence are unreviewed by construction, and that is exactly where a bad premise gets in.

A run that stops without converging, on a budget or a blocker, still posts its trail, and adds the
final comment naming what is open and why it stopped. A ticket that looks sharpened but is not is
the one case where the trail is worth more than the spec.

## Ready check (you, mechanically, before the ticket is offered for signing) · `ready-check`

Once the stop rule is met, check the body line by line. The ticket is ready only when ALL hold:

1. `testable-criteria`: every acceptance criterion is testable, a named test or a named check in
   production can pass or fail it.
2. `route`: the route is stated, build directly, or design first and which trigger fired (more
   than one subsystem or about eight files, an external dependency added or removed, a data
   migration or stored-shape change, a contract other callers rely on, a new long-lived concept).
3. `deploy-order`: where the change ships through more than one pipeline (code, and config, content
   or prompts deployed separately), which ships first, or that they ship together; otherwise "one
   pipeline".
4. `staging-limits`: what staging cannot prove is stated, with how it will be checked in production.
5. `activation`: the activation step is named (the config, credential, external connection or first
   real event that makes it switched on), or "none" with why.
6. `open-questions`: no open question is left, every DECIDE has its answer in the body.

A line passes only with a location, the section of the body where it holds; a pass nobody can point
to is a fail. Why: a ticket can converge and still be unready, because the lenses judge the
requirements, not whether the ticket carries what the release needs, and done means switched on,
not merged.

Post the result as one comment in exactly this shape, because `pickup` parses it:

- first line `READY CHECK: pass` or `READY CHECK: fail`, and `pass` only when all six lines pass;
- then exactly six lines, one per key above, in that order: `[pass] <key>: <where in the body>` or
  `[fail] <key>: <what is missing>`;
- then one blank line;
- then `ELI5:` and the explanation (next section).

```
READY CHECK: fail
[pass] testable-criteria: Acceptance criteria, AC1 by a named test, AC2 by a check in production
[pass] route: Route, design first, trigger: data migration
[pass] deploy-order: Deploy, code first, then config
[fail] staging-limits: not stated
[pass] activation: Activation, none, nothing new to switch on
[pass] open-questions: none left, every DECIDE answered in the body

ELI5: ...
```

Why the fixed shape: a checklist a machine reads is a contract, and a renamed key or a missing line
would otherwise read as a pass.

A fail is fixed in the body and the check runs again. That fix is a late edit, so the stop rule's
re-run of the reconcile applies to it. `pickup` refuses a signed ticket whose latest ready check is
missing or failing (where the project sets `require_ready_check`), so this block is what lets the
ticket be built.

## ELI5 for the person who signs (the last step) · `eli5`

Write a plain explanation for whoever signs: who needs this, what changes for them, why now, and
how we will know it worked. A few short sentences a non-developer follows, no jargon.

It is a test as much as a summary. If it cannot be written without hedging, without contradicting
the body, or without jargon, the ticket is not ready: say which part failed (which question, which
section of the body) and send it back through triage. Why: the signer reads this, not the body, and
a ticket that cannot be explained plainly is one whose author does not yet know what it does.

## Non-negotiables

- An AC that silently orders a subsystem that does not exist is a spec bug: reword to the
  guarantee that is actually buildable and push the subsystem to Out of scope.
- Every AC needs a black-box observable; "the internal state contains X" is not one.
- Match intensity to stakes: a two-line bugfix ticket gets one combined lens pass, the reconcile
  and the ready check, not four rounds. The full flow is for specs a builder will run with; the
  ready check is never skipped, because pickup refuses or flags a ticket without one.

## Relationship to the other gates

This is the SPEC-side gate; the diff-side gates (independent code reviews + one taste gate)
still apply to the code the spec produces. If the machine has a spec-authoring skill (e.g. a
/spec flow that turns vague intent into a draft), author there first - this skill hardens a
draft, it does not create one from nothing.

## When this skill changes

When you change this skill or `intake`, run the process evals in `evals/` (format and run in
`evals/README.md`). A change to a review process is untested until it has caught a known miss again.
