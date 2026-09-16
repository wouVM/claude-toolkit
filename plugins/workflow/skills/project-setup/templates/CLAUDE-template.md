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

<PROJECT-SPECIFIC: deploy rings / environments, standing authorizations, and the hard lines
(what must NEVER be touched without an explicit owner go). Delete this placeholder if none.>
