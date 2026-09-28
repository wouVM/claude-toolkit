---
name: ticket-format
description: >
  The company house format for tickets: a green user-story panel, a blue business-requirements
  panel, a fixed section order (user-facing text, acceptance criteria, what staging cannot prove,
  route/deploy order/activation, out of scope), outcomes only with no technical specs, the
  description as the contract and comments as the trail. Also the path for enriching or rewriting an
  EXISTING ticket: relation scan, draft, checked write-back, then workflow:spec-sharpen. Jira ADF
  panels by default, GitHub alert blocks on GitHub issues. Default format for workflow:intake when a
  project has no house skill of its own. Use when the user says "/ticket-format", "format this
  ticket", "rewrite this ticket", "detail this issue", "put this in house format", or a ticket is
  about to be drafted or reformatted. A NEW ticket from a request starts at workflow:intake.
allowed-tools: Read, Write, Edit, Bash, Agent, Skill
---

# /ticket-format - one ticket format, company wide

ELI16 first: a ticket is read by three kinds of people who never talk to each other. The person who
signs it reads the top two boxes. The builder reads the acceptance criteria. The person who
releases it reads the bottom: what staging cannot prove and what has to be switched on. So every
ticket has the same boxes in the same order, says only WHAT must be true (never HOW to build it),
and keeps the argument about how we got there in the comments, not the body.

A project may have its own ticket skill on top of this one. That skill names only what differs (the
languages user-facing text is written in, the project's example tickets, a tracker I/O workaround,
who the filer is); everything else is this skill.

## Step 0: the config

Read `.claude/pickup.json` from the repo root when it exists. The keys this skill uses:

- `tracker.kind` (`jira` or `github`), `tracker.project` (the Jira project key, or the repo for
  GitHub), `tracker.cloudId` for Jira.
- The status names: `tracker.draft_status`, `tracker.signed_status`, `tracker.in_progress_status`.
  Never hard-code a status name; projects name them differently.
- `relations.closed_window_days` (default 180) and `relations.regression_label`.
- `premises_location`: `"sidecar"` is the house format and what the project-setup template seeds;
  `"body"` is the opt-out for a project that wants `file:line` premises in the ticket (and what a
  config without the key reads as, for backward compatibility). Also `lens_trail.sidecar` (the sidecar
  path pattern, for example `docs/<ticket>-review.md`, with `<ticket>` replaced by the ticket ref)
  and `lens_trail.post_comments`.
- `tracker.diagnosis_kind_marker` (where the diagnosis verdict lives: a label, a field, a body line).
- `require_ready_check`.

Formatting a draft needs none of this. Writing to a tracker does: if the file or `tracker.project`
is absent, say which fields you would need and stop, because a guessed project key writes into
somebody else's board.

## Where to start

- **A NEW ticket from a request** (a client e-mail, a sheet row, a complaint, something we found)
  starts at `workflow:intake`. Intake fetches the source, quotes the reporter, separates symptom
  from inference, diagnoses with `file:line`, runs the relation scan and `workflow:spec-sharpen`,
  and files the draft. Its Step 4 ("draft it in the project's house style") uses the format below
  when the project has no house skill of its own, and the project's house skill (which layers on
  this one) when it does.
- **An EXISTING ticket to enrich or rewrite** uses the workflow further down: read it, run the
  relation scan (required), draft in this format, write back, check the render, then run
  `workflow:spec-sharpen`.

Either way a ticket is not done until spec-sharpen's ready check has passed and been posted as a
comment. Where `require_ready_check` is true, `workflow:pickup` refuses a signed ticket without a
passing `READY CHECK` block.

## The two hard rules

### 1. Coloured panels for the top two sections

| Section | Colour | Jira ADF `panelType` | GitHub alert |
|---|---|---|---|
| User story | green | `success` | `> [!TIP]` |
| Business requirements | blue | `info` | `> [!NOTE]` |

Everything after those two is plain headings and bullets, no panel.

**Jira: panels exist only in ADF.** Markdown input cannot produce a coloured panel, so a description
with panels is written as ADF JSON and sent with `editJiraIssue` (or `createJiraIssue`) and
`contentFormat: "adf"`. The skeleton is at the end of this skill.

Read caveat: `getJiraIssue` and `fetch` downgrade panels to plain text on the way back, and
`responseContentFormat: "adf"` does not help (it still comes back as markdown headings). A plain
read-back therefore cannot tell you whether the panels applied. The check that can: call
`getJiraIssue` with `expand: "renderedFields"` and read `renderedFields.description`, the
server-rendered HTML. A real panel appears as `<div class="panel" style="background-color: ...">`,
and the background colour is the proof:

| Panel | ADF `panelType` | Rendered background |
|---|---|---|
| green (User story) | `success` | `#e3fcef` |
| blue (Business requirements) | `info` | `#deebff` |

A bare `<h2>` with no wrapping `div.panel` means the panels did not apply and the description went
in as markdown. Rebuild it as ADF and send it again; never ask a human to eyeball the browser.

**GitHub issues: the alert blocks are the panels.** `> [!TIP]` renders green and `> [!NOTE]`
renders blue. The marker is the first line of its blockquote, alone; every following line of that
block starts with `>`; alerts cannot nest. The GitHub equivalent is at the end of this skill. The
body comes back from `gh issue view <n> --json body` as the raw markdown, so the check is
mechanical: both markers present exactly, and no line inside either block missing its `>`.

**A plain markdown spec file** (no tracker) uses the same section titles as `##` headings; the
colours are not needed where nobody renders them.

### 2. One syntax per description

Jira wiki markup (`h2.`, `_italic_`, `{quote}`, `{panel}`) mixed into a project whose tickets use
Markdown (`##`, `**bold**`, `>`) renders in different heading styles and fonts, visibly
inconsistent. Write the body in Markdown with `contentFormat: "markdown"`, or in pure ADF with
`contentFormat: "adf"`. Never paste wiki-markup strings, and never mix two syntaxes in one
description.

## Section order

Use these titles, in this order:

1. **User story** (green panel): `As <role>, when <trigger>, I need <capability>, so that <outcome>.`
2. **Business requirements** (blue panel): what the change is, in product terms. May include a short
   **Why** paragraph. When the ticket comes from a request (intake), the panel ends with a
   **Reported** part: the reporter's own words as short verbatim blockquotes, each with its source
   and date ("client, e-mail 24.09", "sheet row 61"), then one plain sentence each for what they saw
   (symptom) and what they think caused it (inference). Where `premises_location` is `"sidecar"`,
   the last line of the Reported part is exactly `Premises and evidence: <lens_trail.sidecar with
   the ticket ref filled in>`.
3. **User-facing text** (only when the ticket introduces copy a user, customer or guest will see):
   each language as its own blockquote, labelled with the language. Which languages, which is the
   default, and the spelling rules belong to the project's house skill.
4. **Acceptance criteria**: plain bullets, outcome level ("When X, then Y"). Simple bullets, not
   verbose GIVEN/WHEN/THEN blocks. Each needs a black-box observable a named test or a named check
   in production can pass or fail.
5. **What staging cannot prove**: bullets naming what a staging or beta test cannot show for this
   ticket, and therefore what the production check after release is (staging points at a vendor's
   demo system; a sender or channel exists only in production; an external side is connected only
   in production). "Nothing, staging covers it" is an answer and must be said. Why: a
   production-only gap discovered in release week was a gap nobody planned for. This is the ready
   check's `staging-limits` line.
6. **Route, deploy order and activation**: three short lines, no tech specs. The route (build
   directly and why, or design first and which trigger fired, as in spec-sharpen's ready check).
   The deploy order when the change ships through more than one pipeline (code, and config, content
   or prompts deployed separately: which ships first, or together; otherwise "one pipeline"). The
   activation step that makes it switched on in production (the admin setting, the credential, the
   external connection, the first real event), or "none" with why. These are the ready check's
   `route`, `deploy-order` and `activation` lines, which must point at a place in the body, so they
   live here and not only in a comment.
7. **Out of scope**: bullets. Call out "no new toggle", "no change to existing behaviour", language
   limits and the like.

**Premises (house default: sidecar).** Intake's PREMISES block (with its `file:line` citations) and
its diagnosis verdict never enter the body: the premises go at the top of the sidecar, which is
also the builder brief, and into spec-sharpen's premise-reconcile comment; the verdict goes into
the sidecar and wherever `tracker.diagnosis_kind_marker` says; the body carries only the one
pointer line at the end of the Reported part. This is `premises_location: "sidecar"`.
The opt-out is `"body"`, for a project that wants `file:line` premises in the ticket itself: there
the premises are the one sanctioned exception to the no-specs rule below, a short cited list under
a **Premises** heading directly after the blue panel (this format's reading of intake's "PREMISES
at the top": the first plain section, above everything the builder reads), worded as evidence of
what the system does today, never as instructions, and the pointer line is dropped.

## Outcomes only: no technical specifications in the body

Never add a "Developer context" section, or any section, carrying technical specifications: no
endpoint shapes, HTTP verbs, URL path formats, model, field or column designs, queue names,
settings keys or file paths, anywhere in the ticket, including as "hints". Older tickets that carry
such a section are not a template.

Why: a spec detail in a ticket becomes both a literal implementation target and a shield against the
real outcome. An AC that reads "shared links wrapped in `GET /r/{token}`" gets built verbatim,
producing exactly the long untrustworthy URL the business wanted to avoid, and then gets quoted
back to deflect the outcome-level criticism.

Instead, express the constraint as an observable outcome: "two customers must never share a URL
segment", not "the name column has no unique constraint". Genuinely useful implementation knowledge
goes in the sidecar review file, the PR, or chat, never in the ticket.

**What intake hands over, and where it lands**, so nothing it produces is dropped and nothing
technical enters the body:

- **In the description:** the reporter's short verbatim quotes with source and date, and symptom
  versus inference in plain words, in the Reported part of the blue panel. They are evidence, not
  specs: a quote that happens to name a mechanism stays verbatim as a quote and never becomes an AC.
- **Not in the description** (in sidecar mode): the PREMISES block and the diagnosis verdict, as in
  "Premises" above.

## Description = contract, comments = trail

- **The description is the contract**: requirements, acceptance criteria, scope. A change to any of
  these is an EDIT to the description, never a comment, so the body always reads standalone.
- **Comments are the record of how we got there, and they are required**: each lens with its
  findings' fates, the premise reconcile, the ready check, a build claim, a review round, a stop.
  A decision that lives only in a chat window is lost when the chat closes.

Where `lens_trail.post_comments` is false, the trail goes to the sidecar and the report instead.

## Writing rules

- **No em dashes, no arrow glyphs** in ticket content: readers take `—`, sentence-punctuation `–`
  and `→` as tells of machine-written text. Use commas, semicolons, colons, parentheses or a new
  sentence. En dashes inside technical ranges (`L109–122`) are fine.
- **First person for the filer**: text written on someone's behalf says "I did X", never "<name> did
  X". The project skill names who the filer is.
- **Tracker call hygiene**: pass `fields` to `editJiraIssue` as a real JSON object, never a
  stringified blob (a raw JSON string fails validation with "could not be parsed as JSON"). On
  GitHub, write the body to a file and use `--body-file`, never an inline `--body` with shell quoting.
- When the caller wants a draft to review before anything is written to the tracker, write the same
  sections to a `.md` file and stop there.

## Workflow: enrich or rewrite an EXISTING ticket

For a NEW ticket from a request, run `workflow:intake` instead; it does its own relation scan and
uses this format for its drafting step.

1. **Read the ticket and its state.** Jira: `getJiraIssue` with `fields: ["*all"]` and
   `responseContentFormat: "markdown"`. GitHub: `gh issue view <n> --json
   title,body,state,labels,comments`. Read its status and history too. A ticket in a done status or
   in `tracker.in_progress_status` means the rewrite rests on a stale premise: STOP and confirm with
   the human before overwriting anything.
2. **Relation scan (REQUIRED, before any rewrite).** Run intake's Step 3 against this ticket, with
   the salient keywords of the capability, excluding the ticket itself:
   - OPEN tickets in the project. Jira: `project = <KEY> AND statusCategory != Done AND text ~
     "<keyword>"`, one query per keyword set. GitHub: `gh issue list --repo <REPO> --state open
     --search "<keywords>"`.
   - CLOSED tickets within `relations.closed_window_days`. Jira: `project = <KEY> AND statusCategory
     = Done AND resolved >= -<days>d AND text ~ "<keyword>"`. GitHub: `gh issue list --repo <REPO>
     --state closed --search "<keywords> closed:>=<date>"`.
   - The capability itself, in the tracker and in the code: "can we do X" often means "does X work
     yet", and the answer may be a shipped ticket or a flag that is already there.

   One verdict, judged on meaning, never on shared words:
   - **duplicate** of another OPEN ticket: STOP. Do not rewrite. Propose amending the open ticket
     with this one's evidence (and closing this one as its duplicate); the human decides.
   - **regression-of** a CLOSED ticket: link it, say in the body that this is a recurrence of
     `<ref>` closed on `<date>`, and apply `relations.regression_label` where the project has one.
   - **related** or **sub-issue**: link it and carry on.
   - **new**: carry on.

   If the tracker is unreachable (the connector is not authorised, the MCP server is not loaded,
   the token is rejected), STOP and say exactly what is missing. Never skip the scan silently, and
   never rewrite or file without it. A project skill may name a workaround I/O channel for its
   tracker; the scan's judgment still runs in this session, and the channel only carries reads and
   writes.
3. **Study the house style** if unsure: search the project's recent tickets (Jira: `project = <KEY>
   ORDER BY created DESC` with `searchResultMode: "issues"`) and read a couple of well-formed ones;
   the project skill may name its reference tickets. Large result sets get spilled to a file;
   extract from it with `jq`.
4. **Ground the detail in the code** before writing requirements; never invent behaviour. Dispatch
   a read-only search (`workflow:explorer`, cheap model) to confirm how the feature works today,
   its options, flags and language handling.
5. **Draft** in the section order above.
6. **Write it back.** Jira with panels (the normal case): build ADF from the skeleton below and call
   `editJiraIssue` with `contentFormat: "adf"`; with no panels, `contentFormat: "markdown"`. GitHub:
   `gh issue edit <n> --repo <REPO> --body-file <file>`.
7. **Confirm the render**: Jira via `expand: "renderedFields"` (look for `#e3fcef` and `#deebff`);
   GitHub via the mechanical marker check above. The plain API read-back hides Jira panels.
8. **Sharpen**: run `workflow:spec-sharpen` on the ticket, with the addendum below. Every body edit
   it makes goes back in this format with the panels intact. It ends with the ready check and ELI5
   comment that `workflow:pickup` parses, so that comment is the LAST write: pickup treats a
   description edited after the ready check as a fail, and any later edit means re-running the
   premise reconcile and the ready check.

## Sharpening: `workflow:spec-sharpen`, with this addendum

Drafting in the house format is step one, not done: every ticket gets `workflow:spec-sharpen`
(its lenses, the premise reconcile, DECIDE/DEFER/KILL triage with the trail posted as comments, the
stop rule, then the ready check and ELI5). Do not restate its rounds; that skill is the source. What
follows is what the house format adds. Apply each item where its tag says.

**Dev lens scan list** `[dev lens brief]`. Besides what spec-sharpen names, the scan reports
provenance signals (how we can tell where a stored value or a message came from) and which layer
owns the behaviour: code, configuration, or content the system reads at runtime (templates,
prompts, admin settings). The project skill may name its layers.

**Observables** `[TPM lens brief, ready check]`. An AC's black-box observable is something a person
outside the code can see: a screen, a message a user receives, an e-mail, a report row. "The
internal context contains X" is not one. The project skill may list its usual observables.

**Sidecar = builder brief** `[reconcile]`. The review sidecar is `lens_trail.sidecar`. Premises
with `file:line` go at its top, and where the project's build skill reads a brief, the same file is
that brief: premises, allowlist, shape, tests. Mechanism recommendations live there or in the PR,
never in the ticket body.

**Third-party claims: a `file:line` is not enough** `[reconcile, dev lens brief]`. A citation proves
only that WE believe something, and a code comment is hearsay that a confident tone promotes to
fact. Example: a ticket built on "the provider has no modify operation", cited to a comment in our
own service next to the workaround built on that belief, passes every lens; a four-minute probe of
the provider's public API finds the modify endpoint, and the ticket's whole shape was solving a
problem that did not exist.

- **A verified fact has a date.** A supplier's "planned, no release date yet" is true on the day it
  was written and stale a release cycle later. A citation to a supplier's answer carries its date,
  and a claim older than a release cycle is re-probed before a ticket is built on it.
- **Check the supplier correspondence, not only our code.** The answer often sits in a mail thread
  nobody re-read. Search the team mailbox through its connector, including spam.
- **Verify against their system, or mark it.** Every claim that an EXTERNAL system cannot do
  something, or behaves a particular way, is checked against that system (call the API, read their
  docs), or it is marked UNVERIFIED in the ticket and the ticket is written so the build works
  either way.
- **Cheap probes that need no transaction and no credentials:** a public read endpoint; a write call
  with a deliberately invalid identifier, where a 400 on the payload versus a 404 on the object tells
  you which payload shapes are accepted.
- **Read what their configuration exposes that we never read**: a per-customer switch or setting on
  their side (a "customer may edit" flag, a per-account timezone) that our code ignores.

**Always material, never triaged away on a body-only reading** `[triage]`. Any finding of the form
"which layer does this behaviour actually live in?", "this AC assumes X is content-driven or
code-driven and that is unstated", or "we assume the third party cannot do Y". Example: a finding
that asks which layer owns a refusal message, triaged as non-material, lets a ticket ship a
per-customer rollout of wording changes when the message is hardcoded in the backend and no wording
change can reach it.

**Folding findings in** `[triage]`. DECIDEs land in the body as outcomes only; the no-specs rule
applies to lens findings in full. A change to requirements, ACs or scope is an edit to the
description, never a comment; the comments are the trail and are required. The ready check comment,
which cites the Route section of the body, also serves as the "route stated in a comment" record a
project may require.

## Jira ADF skeleton

Pass this shape as `fields.description` with `contentFormat: "adf"`. Replace the placeholder text;
add a Premises section after the blue panel only in `"body"` mode, and the User-facing text section
only when the ticket has copy.

```json
{
  "version": 1,
  "type": "doc",
  "content": [
    { "type": "panel", "attrs": { "panelType": "success" }, "content": [
      { "type": "heading", "attrs": { "level": 2 }, "content": [{ "type": "text", "text": "User story" }] },
      { "type": "paragraph", "content": [
        { "type": "text", "text": "As " },
        { "type": "text", "text": "<role>", "marks": [{ "type": "strong" }] },
        { "type": "text", "text": ", when <trigger>, I need <capability>, so that <outcome>." }
      ] }
    ] },
    { "type": "panel", "attrs": { "panelType": "info" }, "content": [
      { "type": "heading", "attrs": { "level": 2 }, "content": [{ "type": "text", "text": "Business requirements" }] },
      { "type": "paragraph", "content": [{ "type": "text", "text": "<what the change is, in product terms>" }] },
      { "type": "paragraph", "content": [{ "type": "text", "text": "Why: <the pain or rationale>", "marks": [{ "type": "em" }] }] },
      { "type": "heading", "attrs": { "level": 3 }, "content": [{ "type": "text", "text": "Reported" }] },
      { "type": "blockquote", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "<reporter's words, verbatim> (<source>, <date>)" }] }] },
      { "type": "paragraph", "content": [{ "type": "text", "text": "Symptom: <what they saw>. Inference: <what they think caused it>." }] },
      { "type": "paragraph", "content": [{ "type": "text", "text": "Premises and evidence: <sidecar path>" }] }
    ] },
    { "type": "heading", "attrs": { "level": 2 }, "content": [{ "type": "text", "text": "User-facing text" }] },
    { "type": "paragraph", "content": [{ "type": "text", "text": "<Language>:", "marks": [{ "type": "strong" }] }] },
    { "type": "blockquote", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "<copy>" }] }] },
    { "type": "heading", "attrs": { "level": 2 }, "content": [{ "type": "text", "text": "Acceptance criteria" }] },
    { "type": "bulletList", "content": [
      { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "When <X>, then <Y>." }] }] }
    ] },
    { "type": "heading", "attrs": { "level": 2 }, "content": [{ "type": "text", "text": "What staging cannot prove" }] },
    { "type": "bulletList", "content": [
      { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "<gap, and the production check that covers it>" }] }] }
    ] },
    { "type": "heading", "attrs": { "level": 2 }, "content": [{ "type": "text", "text": "Route, deploy order and activation" }] },
    { "type": "bulletList", "content": [
      { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Route: <build directly, because ...> or <design first, trigger: ...>" }] }] },
      { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Deploy order: <one pipeline> or <which ships first>" }] }] },
      { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Activation: <what switches it on in production> or <none, because ...>" }] }] }
    ] },
    { "type": "heading", "attrs": { "level": 2 }, "content": [{ "type": "text", "text": "Out of scope" }] },
    { "type": "bulletList", "content": [
      { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "<excluded item, and a brief reason>" }] }] }
    ] }
  ]
}
```

Drop the Reported block when the ticket did not come from a request, and its pointer line when
`premises_location` is `"body"`.

## GitHub equivalent

```markdown
> [!TIP]
> **User story**
>
> As **<role>**, when <trigger>, I need <capability>, so that <outcome>.

> [!NOTE]
> **Business requirements**
>
> <what the change is, in product terms>
>
> *Why: <the pain or rationale>*
>
> **Reported**
>
> > <reporter's words, verbatim> (<source>, <date>)
>
> Symptom: <what they saw>. Inference: <what they think caused it>.
>
> Premises and evidence: <sidecar path>

## User-facing text

## Acceptance criteria

## What staging cannot prove

## Route, deploy order and activation

## Out of scope
```

The two alert blocks must be separated by a blank line that does not start with `>`, or GitHub
reads them as one block.
