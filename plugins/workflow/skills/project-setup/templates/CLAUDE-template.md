# <PROJECT-NAME>

<ONE PARAGRAPH: what this project IS, what it is NOT, and the one drift to guard against.
Name the load-bearing nouns (the app vs the agent vs the service) so they never blur.>

<LAYOUT: a short tree of the top-level directories and what truth lives in each.>

## The doc-map (which truth lives where)

Each kind of truth has one home, so the stable docs never carry the fast-changing stuff.
Every one of these is "the current best answer": when reality moves, update the doc FIRST, then implement.

- **CLAUDE.md** (this file) - HOW we work: principles. Changes rarely.
- **WHERE WE ARE today** - `git log` (the diary) + the GitHub issues. Deliberately NOT a ledger
  file: a standing "current status" snapshot is a currency tax duplicating git + issues.
- **`DEFERRED.md`** - what is consciously NOT built yet, each entry keyed to the condition that
  reopens it.
- **`TRAPS.md`** - the trap book (see below).
- **`FAULT-CATALOGUE.md`** - process faults caught or admitted, current-state (git tracks history).

## Working agreements (non-negotiable principles)

- **Kernel mode, always.** Think like a kernel engineer, not a web programmer bolting features on.
  Principled and minimal by default: every change earns its place in a coherent system and is
  correct at the seam. Reject the well-meaning heuristic patch that makes one case pass and quietly
  compounds into debt; find the principled form, or escalate. No cleverness for its own sake, no
  cruft, no apologies. The standard is a design you would defend to Linus.
- **ELI16 by default.** Explain in plain words first and jargon second, everywhere.
- **Do not retain pointers to the past.** In docs AND code: state the CURRENT solution, not what it
  used to be. Git holds the history; a stale "this replaces the old X" line, or a comment narrating
  a change, is rot. Delete and restructure toward what we know now, without apology.
- **Minimize code surface.** No one-off hacks, ever: absorb each special case into a principled
  fix. No heuristics. If you catch yourself adding a detail to make one thing work, find the
  general form or escalate.
- **Proportionality (measures fit the problem, like in law).** The effort, machinery, and
  permanence of a fix must be proportional to the size and frequency of the problem it solves. A
  rare, one-off, or scheduled event does NOT justify permanent hot-path machinery; a small bug does
  not justify a framework. Over-engineering is rot as surely as a hack.
- **Lib-first, and example-repo-first.** BEFORE hand-rolling a load-bearing feature, check whether
  a trusted library or official vendor SDK owns it, AND look for an example repo or reference
  implementation to build the SHAPE off from. Two HARD gates before adopting a dependency:
  (1) LICENSE compatible with this project's distribution model (record the call in the adoption
  note); (2) it must run in this project's runtime - for a large dep, MEASURE the bundle first.
  Glue is a signal the fit is wrong, not that you should hand-roll instead.
- **The trap book (`TRAPS.md`) - for RECOGNITION, never as a licence.** One file holds the shapes
  this project has already fallen into. READ it while you work and check your own work against it;
  if you find you have done something similar to what is recorded there, reflect and remediate.
  Writing a shortcut down does not pay for it: an entry records a FAILURE, never a receipt. And the
  book is NOT a TODO list - a thing that still has to be fixed is a tracked issue; the book keeps
  only the shape. A genuinely NEW shape earns a new entry; a recurrence SHARPENS the entry it
  matches; never append a round's diary. The instrument is readability, not length.
- **Migrations leave no technical debt.**
- **Every problem solved becomes a test** at the layer that catches it (assert at real STATE - the
  database row, the API response, the rendered screen - never a tautology or a flaky
  natural-language reply).
- **Spikes are disposable:** throwaway experiments in `./spike/` (gitignored), scratch in
  `./_scratch/` (gitignored). The ASSET is the finding, folded into the design record; the code is
  not kept.

## Cost discipline (role-to-model, not cheapest-everywhere)

- **The COORDINATOR directs and checks** the judgment nodes where one wrong call costs a whole phase: the
  spec, the plan review, the diff review, any taste call or one-way door.
- **The BUILDER executes** the build: the code, with the existing suite kept green. Its new tests come from a
  separate agent (`workflow:test-writing`), which tests what was promised rather than how it was built.
- **The SCOUT explores** the cheap-to-verify fan-out: repo search, scouting, reading long documents.

Set per-agent (`Agent` `model:`) or per-stage; never downgrade the whole session. Put a token budget on
every autonomous run and a file-allowlist + no-crawl on every subagent prompt.

**The reads are the cost, not the edits.** A coordinator that has already read the source has spent the
budget the delegation was meant to save, and will then reason that delegating means paying twice. So the
decision belongs BEFORE the first read of build source, not after - and the moment a design session turns
into a build is exactly the moment nothing announces. Two pre-written paths make the correct move the cheap
one: `/build` to hand a spec to a builder, `/digest` to hand a long document to a scout.

This is enforced, not just written: `.claude/hooks/builder-model-guard.sh` denies coordinator-model edits to
build code. It fails open on every unknown and never fences a subagent.

## `gh#N` is a GitHub issue

A `gh#N` in any text (chat, a doc, a commit message) means GitHub issue N in this repo, filed via
the `/issue` skill. It is deliberately distinct from a bare `#N`, which is a Claude Code session
task number: ephemeral, never cited in committed prose. Every OPEN TODO belongs to a gh issue.
Only OPEN work becomes an issue - a done / solved item is NEVER filed; git history is its record.
Implementing an issue starts by MAPPING its network (parent, blockers, `Relates to` links), never
reading it in isolation.

## Landing gates (how work lands)

Work lands in small, reviewed commits; commit messages are a diary (use git generously).
On a finished chunk of work or a load-bearing diff:

1. Read `TRAPS.md` FIRST - the work you are about to do is the work most likely to repeat one.
2. Build foundation-first. Every problem solved becomes a test.
3. **Seen-running gate:** a change is not green until it has been observed working in the real app,
   not only in unit tests. For UI work that means driving the live app with the machine's browser
   tooling (e.g. a Playwright-based QA skill or the Playwright MCP): desktop AND mobile widths,
   both color themes if the app has them, and the actual user flow end to end. Agent screenshots
   inform; they do not replace the responsible human's own look at anything user-facing.
4. Close with the independent reviewers: the CORRECTNESS gate is every independent code reviewer
   this machine has (e.g. `/codex review` + `/gemini review`), run in parallel - land only when
   all pass, and a single VERIFIED defect overrides a majority "pass". Then ONE taste gate
   (`/gemini judge` for a routine diff, `/springclean` for a load-bearing one): was this the RIGHT
   work - proportionate, no hand-rolling, honest? A correctness gate cannot reject a design: when
   a fix fails a SECOND review round with a brand-new defect, stop patching and run the taste gate
   before attempting a third.
5. MAINTAIN `TRAPS.md` (sharpen the trap this round wore; add one only for a genuinely new shape)
   and file every open TODO the round leaves as a gh issue. Report what shipped, and every
   adhockery (propose fixes, never leave rot).

<DELETE the next two sections unless the project took the production read-only piece. Fill every
slot from docs/runbooks/prod-readonly-access.md once the admin steps are done; never paste a
password, key or connection string with a password into this file.>

## Reading production (READ-ONLY)

Status: <NOT ACTIVE YET: waiting on the admin steps in docs/runbooks/prod-readonly-access.md |
ACTIVE since <DATE>, read-only verified>. While it says NOT ACTIVE, do not read production at
all, by any credential.

Production is readable and CANNOT be written from this machine. That is deliberate, not a
misconfiguration, and not something to work around.

- Identity: <RO-IDENTITY: the read-only cloud identity, and what it may do (connect to the database,
  read logs, read the one read-only secret)>. The human's personal login and application-default
  credentials are revoked on purpose.
- Database login: <RO-DB-ROLE>: SELECT only, `default_transaction_read_only = on`. Verified
  <DATE> from the privilege catalogue, never by attempting a write: <VERIFIED-READ-ONLY: the step 8
  result, e.g. "default on; no write path: 0 relations, 0 sequences, 0 schemas with CREATE, 0
  SECURITY DEFINER functions, no role attributes">.
- Never test the read-only guard by writing, not even a rolled-back or temporary write. The
  catalogue check is the test.
- Connect: <CONNECT-COMMAND: how to fetch the read-only settings into a local file and start the
  proxy if it is not running, as a copy-paste block>
- Run a query: <QUERY-RUNNER: the command that runs a read-only SQL or shell script against those
  settings>
- Check it still works: `bash scripts/tools-check.sh` (the `prod-db` check).

The fixed rules:

- **Never look for a read-write credential.** Not in env files, secret stores, shell history,
  password managers, or other checkouts. If something needs more than SELECT, that is the answer:
  it is not yours to do.
- **Never ask the human to log in just to read something.** Everything readable works as-is
  through the read-only path. A read that fails is a finding to report, not a reason to escalate
  credentials.
- **Anything that writes to production is the human's act**: enqueueing a job, fixing a row, a
  migration, a config change, a redeploy. Report exactly what needs doing, with the command, and
  stop.
- **Never print credentials or personal data.** Do not echo a secret, a settings file or a
  connection string. Query for counts, ids and the columns the question needs; do not paste names,
  e-mails, phone numbers or message contents into chat, tickets, commits or docs. Quote an id and
  say where the row lives instead.
- Full setup and who does what: `docs/runbooks/prod-readonly-access.md`.

## Reading logs

- Command: <LOG-COMMAND: the log read under the read-only identity, e.g. a cloud CLI log query with
  the project, a filter, --limit and --freshness>
- Always filter narrowly (service, severity, a request or conversation id) and keep `--limit` small;
  widen only when the first read shows it is needed.
- Log lines carry personal data and sometimes tokens: summarise what they show (counts, error
  types, timestamps, ids), never paste raw lines into a ticket or chat.
- Check it still works: `bash scripts/tools-check.sh` (the `logs` check).

<PROJECT-SPECIFIC: deploy rings / environments, standing authorizations, and the hard lines
(what must NEVER be touched without an explicit owner go). Delete this placeholder if none.>
