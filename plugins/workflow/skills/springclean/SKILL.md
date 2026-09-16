---
name: springclean
description: Close a work cycle or review a diff with a bad-tempered adversarial PANEL that grades the work as an OUTCOME ("achieved" or not) against a taste-and-proportion rubric, one grumpy reviewer per lens, each citing files. This is the taste half of the landing gate (correctness is your independent code reviewers, e.g. /codex review + /gemini review); it is the structured, multi-lens expansion of /gemini judge. Use it whenever a chunk of work is wrapping and about to be called green, a load-bearing diff is about to land, or the user says "springclean" / "spring cleaning" / "lentekuis" / "clean up this sprint" / "is this over-engineered" / "did we hand-roll something a lib owns" / "are these tests real" / "judge the shape of this work". Reach for it any time you want an independent proportion-and-honesty read that is DISTINCT from "does it work", even when the user does not name it.
---

# /springclean - the lentekuis (spring cleaning)

ELI16 first: a "lentekuis" (Dutch for spring cleaning) is the moment at the end of a chunk of work where you
stop asking "does it work?" and start asking "is it the RIGHT SHAPE?". Green tests and a passing code review
tell you the code is correct. They do NOT tell you it is proportionate, un-hand-rolled, simple, honestly
tested, and free of fronted pretenses. Those are TASTE judgments, and a builder is the worst judge of their
own taste, so we outsource it to a panel of deliberately grumpy reviewers who each hunt ONE sin.

This is the taste-and-proportion half of the landing gate. The correctness half is your independent code
reviewers (run every one this machine has - e.g. `/codex review` + `/gemini review` - in parallel). The
lentekuis is the structured, multi-lens expansion of `/gemini judge`: same job (was this the RIGHT work),
broken into named lenses so nothing hides in an averaged "seems fine".

## Spring cleaning is an OUTCOME, graded "achieved"

Do not run this as a vibe. There is a rubric, the panel produces a grade, and the grade is `achieved` or
`not achieved` with the reasons. Thinking in graded outcomes is the point - it forces the panel to defend a
verdict, not just emit opinions.

The rubric (what "achieved" means for the shape of the work):

- **No code slop.** Every line earns its place; no dead ballast, no cruft, no apologies in comments.
- **No deferring as a dodge.** A real deferral names its EXIT (the condition that reopens it) and lands in
  the tracker. A "TODO" or a swallowed error with no named exit is a pretense, not a deferral.
- **No hand-rolling what a trusted lib or vendor owns.** Bringing in a lib is ALLOWED and often correct: a
  proven dependency is not the enemy. Reinvention is. GLUE around a lib is the smell that the fit is wrong.
- **Proportionality.** The machinery matches the size and frequency of the problem. A rare or scheduled event
  does not justify permanent hot-path machinery; a small bug does not justify a framework.
- **Maintainable complexity.** The codebase must not drift toward un-maintainable. Ask: could a fresh
  engineer hold this in their head?
- **Special cases are inversely proportional to framework quality.** Every special case is a small confession
  that the general mechanism is not general enough. Count them. A rising special-case count is a design smell,
  not a feature.
- **Always point at the generalization.** When the panel finds special-casing or duplication, its job is not
  only to flag it but to name the more general mechanism that would DISSOLVE it.
- **Balanced judgment.** The lenses pull against each other on purpose (add-a-lib vs do-not-over-depend;
  generalize vs do-not-over-engineer-for-the-unlikely). The synthesis strikes the balance; a lens finding is
  an input to judgment, not an automatic verdict.

## The five lenses (one grumpy reviewer each, told to be specific and cite files)

Give each reviewer EXACTLY ONE lens and tell it to be blunt, adversarial, and concrete (file + line + the
failure it implies). One lens per agent keeps the reviews independent and stops a single "looks fine" from
smearing over a real sin.

- **overdoing-it** - overhedging, overengineering, permanent hot-path machinery for very unlikely events. A
  rare or scheduled event does not justify a framework; over-engineering is rot as surely as a hack. Hunt the
  guard that defends against a case that cannot happen, the retry around a call that does not fail, the
  abstraction with one caller.
- **soloing** - hand-rolling what a trusted library or vendor SDK already owns. New deps are FINE (see the
  rubric); flag REINVENTION, not dependency. Hunt the parser, state machine, crypto, date math, or protocol
  the team wrote by hand when npm or the vendor SDK owns it. Glue around a lib is the tell.
- **KISS** - added complexity or special-casing where a SIMPLER, more general mechanism does the same job.
  Hunt the branch that a data-structure change would erase, the three near-identical functions that want to be
  one, the config knob nobody sets.  Name the general form.
- **oversimulating** - `assert(1+1==2)`-shaped tests that restate the implementation and prove nothing, and
  ESPECIALLY any test an end-to-end test (an agent or harness driving the real API or the real UI, asserting
  at STATE: the database row, the API response, the rendered screen) would cover better. Never a tautology and
  never a flaky natural-language reply. Hunt the test that would pass even if the feature were deleted.
- **adhocke-yeyey** - fronting: tracking an adhockery or a "pretense" (a stub, a swallowed error, a hardcoded
  value dressed as dynamic, a "deferred" with no named exit) as a COP-OUT in place of the real thing. A
  confession with no path is rot; a real deferral names its exit. Hunt the thing that LOOKS done and is not.

## How to run it

1. **Scope.** Name the exact commit range or diff under review (`git diff <base>..HEAD`). The panel reads the
   repo itself; do not paste code.
2. **Match the intensity to the stakes - do NOT over-run a taste check (the overdoing-it lens applies to
   THIS skill too).** For a small or routine diff, one reviewer sweeping all five lenses in a single pass - or
   just a `/gemini judge` - is enough; do not spin up a fleet to eyeball a few files. Reserve the FULL fan-out
   (one independent reviewer agent per lens + a synthesis stage - dispatch this plugin's `reviewer` agent,
   one per lens, via the `Workflow` tool or parallel Agent calls, NONE of them the builder) for a
   LOAD-BEARING landing where the
   lenses genuinely need to be split out and defended. Independence is the point at either intensity. Each
   reviewer returns findings ranked by severity, each with a file cite and the concrete failure it implies.
3. **Rebuttal loop.** For each finding, the builder answers "why". A finding that SURVIVES the rebuttal (the
   reviewer sustains it against the answer) is a VERIFIED finding. A finding the rebuttal dissolves is dropped
   (record the good ones the panel got wrong - the lentekuis earns trust by dropping false positives with
   reasons, not by racking up a count).
4. **Synthesize into a graded verdict.** A synthesis agent (again, not the builder) reads all sustained
   findings and produces: (a) the grade - `achieved` or `not achieved`; (b) for every special-case /
   duplication finding, the GENERALIZATION that would dissolve it; (c) the balance call where lenses conflict.
   State the grade as a sentence someone who never saw the diff can act on.

## Folding the findings (the close)

- A sustained finding must be FOLDED before the work is called green: FIXED now, or HONESTLY deferred as a
  tracked issue with a named exit. Never fronted, and never parked as a note in a repo file - if the project
  keeps a trap book (`TRAPS.md`), it keeps the SHAPE (sharpen the trap the round wore; add one only for a
  genuinely new shape); the issue keeps the WORK.
- **One sustained finding blocks green exactly like a verified reviewer defect.** The builder's own green is
  never the close signal; the panel's verdict is. Green suites and a single reviewer routinely miss a real
  problem that a second independent voice catches.
- A sin that RECURS gets an entry in the project's fault catalogue (`FAULT-CATALOGUE.md`, if the project
  keeps one) so `/gemini judge` and future lentekuisen can catch the repeat. The same fault repeated unlogged
  is the real failure.

## Relationship to the other gates (so nobody double-counts)

- The independent code reviews (`/codex review`, `/gemini review`, or whatever reviewers this machine has) =
  the CORRECTNESS gate (does it work, is it secure, are contracts intact). Two vendors by design when
  available, not redundant - a verified defect from either overrides. Run all you have.
- `/gemini judge` and `/springclean` are the SAME taste gate at two INTENSITIES, not two gates: run ONE, scaled
  to stakes, NEVER both on the same diff. `/gemini judge` is the single-voice lightweight read (a routine
  diff); `/springclean` is its full multi-lens adversarial form (a load-bearing landing, or a shape you are
  unsure of). Both judge PROPORTION + honesty against the same rubric (the project's `.claude/gemini-judge.md`
  when present); they do not stack.
- So a whole-diff or one-way-door landing wants TWO gates total - the correctness gate and ONE taste gate
  (judge OR springclean) - not four. A single verified defect from either gate overrides a majority
  "looks fine".
