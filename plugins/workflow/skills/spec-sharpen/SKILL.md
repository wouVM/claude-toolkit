---
name: spec-sharpen
description: >
  Sharpen a spec, ticket, issue, or requirements doc through independent multi-pass review
  until it is SIGNABLE: a fresh-agent TPM lens, a code-grounded dev lens, a cold exhaust
  pass, and a mechanical premise reconcile (every present-tense claim about current system
  behavior gets a file:line citation or gets reworded out), with DECIDE/DEFER/KILL triage
  and a convergence stop rule. This is the spec-side landing gate that makes spec-driven
  development real: defects caught here never reach the build. Works on a Jira ticket (via
  the Atlassian MCP), a GitHub issue (via gh), or a plain markdown spec file. Use when the
  user says "sharpen this spec/ticket", "are these requirements complete", "make this
  signable", "spec-driven", or before handing any non-trivial spec to a builder (human or
  agent). NOT for reviewing code - that is the diff-side gate.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, AskUserQuestion
---

# /spec-sharpen - multi-pass requirements review until signable

A drafted spec is step one, not done. The build inherits every ambiguity, false premise, and
undecided question the spec carries, at 10x the cost. So the spec gets the same review rigor
a diff gets: independent lenses, adversarial passes, and a convergence rule.

**Fresh agents are the mechanism.** A model defends the reasoning it just produced; a cold one
argues with it. Never run a lens inside the context that drafted the spec. You (the
orchestrator) own the end result and make the edits; each lens is a fresh agent dispatched
via the Agent tool with the spec BODY only, never the drafting conversation.

## Step 0: Locate the spec and its home

The spec lives where the team tracks work; read it from there and write it back there:
- **Jira ticket**: `getJiraIssue` via the Atlassian MCP (if connected).
- **GitHub issue**: `gh issue view N --json title,body`.
- **Markdown file**: read the path the user names.

The review record (premises, findings, triage fates, mechanism notes for the developer) goes
to a sidecar file next to the project's docs (e.g. `docs/<ref>-review.md`), NEVER into the
spec itself.

## The hard rule: outcomes, never mechanisms

Requirements state WHAT must be observably true, in product terms. No endpoint shapes, HTTP
verbs, model/field designs, queue names, settings keys, or file paths - anywhere in the spec,
including as "hints". A spec detail becomes both a literal implementation target AND a shield
against the real business outcome ("but the ticket said GET /r/{token}"). Express constraints
as observable outcomes ("two venues must never share a URL segment", not "add a unique
constraint on name"). Genuinely useful implementation knowledge goes in the sidecar review
file or the PR, never the spec. This rule fully applies to lens findings when you fold them in.

## Round 1 - TPM lens (fresh agent)

Give the agent the spec body only, and this lens:
- Scope boundaries: what is explicitly out? Any requirement claimed both in and out?
- Edge cases: named now, not discovered mid-build.
- Compliance exposure: what data, whose, logged where, deleted how?
- Acceptance criteria: verifiable by someone who never reads the code - an observable
  surface (a screen, a column, an export) must exist for every AC.
- "What does this spec not decide?"

Bar: **could this be signed off without reading the diff?**

## Round 2 - Dev lens (fresh agent, code-grounded)

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

## Round 3 - Exhaust (fresh agent, cold)

A fresh agent that has seen NONE of the prior rounds gets the CURRENT spec body and exactly
this prompt:

> "Enumerate everything this doesn't decide and every way it can break. Keep going until
> exhausted; organize by category."

## Round 4 - Premise reconcile (you, the orchestrator - NOT an agent)

The lenses' blind spot: they are given the spec body only, so **a false claim about how the
system works today passes all of them unchallenged**. Round 2 sees code, but it is asked what
will break during the build, not whether the spec's description of current behavior is true.
Nobody owns that unless you do. Mechanically:

1. Extract every sentence asserting present-tense system behavior ("today the user gets X",
   "this is currently produced by Z").
2. Give each a `file:line` citation from the code scan. No citation means it is a guess:
   verify it or reword it out.
3. List the premises at the top of the sidecar review file, so a human who knows the system
   can falsify them in one read - the cheapest check available; make it easy.

Treat as **material, never triaged away on a body-only reading**, any finding of the form
"which layer does this behavior actually live in?" or "this AC assumes X is config-driven /
code-driven and that is unstated." A spec has shipped a whole rollout justified entirely by
a false premise that an exhaust pass HAD flagged and triage dismissed.

## Triage - every finding gets exactly one of three fates

- **DECIDE now**: resolve it and write the outcome into the spec.
- **DEFER**: with a one-line reason, stated in the spec (usually Out of scope).
- **KILL**: noise, drop it silently.

Where a DECIDE needs the user (a genuine stakeholder call), batch the questions and ask once
via AskUserQuestion; an unresolved stakeholder question is a BLOCKER, not a footnote - either
get the answer or write the chosen default into the spec with its rationale ("err on X
because Y") so the spec is signable either way.

## Stop rule

Done when **two consecutive further passes change no decision** AND the premise reconcile is
clean: re-run the exhaust prompt on the updated spec; if two passes in a row produce only
DEFER/KILL fates and zero new DECIDEs, and every present-tense claim carries a citation, the
spec is signable. Re-run the reconcile after ANY late edit - edits made after convergence are
unreviewed by construction, and that is exactly where a bad premise gets in.

## Non-negotiables

- An AC that silently orders a subsystem that does not exist is a spec bug: reword to the
  guarantee that is actually buildable and push the subsystem to Out of scope.
- Every AC needs a black-box observable; "the internal state contains X" is not one.
- Match intensity to stakes: a two-line bugfix ticket gets one combined lens pass and the
  reconcile, not four rounds. The full flow is for specs a builder will run with.

## Relationship to the other gates

This is the SPEC-side gate; the diff-side gates (independent code reviews + one taste gate)
still apply to the code the spec produces. If the machine has a spec-authoring skill (e.g. a
/spec flow that turns vague intent into a draft), author there first - this skill hardens a
draft, it does not create one from nothing.
