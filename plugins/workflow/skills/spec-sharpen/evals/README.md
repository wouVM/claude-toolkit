# Process evals: test the sharpening flow like code

ELI16 first: we test code by running it against cases where we know the right answer. This does the
same for the ticket flow. A case is a past ticket where something slipped through. We run the flow
on the ticket as it was first drafted and check whether it now catches what it missed then. If a
change to `intake` or `spec-sharpen` makes the flow miss a case it used to catch, that change made
the flow worse, however good it reads.

## Where cases live

In the PROJECT, not here: `docs/process-evals/<case>/` or wherever the project keeps docs. Drafts are
project data, and a toolkit that shipped them would leak one project into every other. This folder
ships the format, the run procedure, and one worked example (`example-late-booking-reminder/`),
which is invented to show the shape and is not a real case.

## A case

One folder per case, named after the miss, holding:

- `draft.md`: the ORIGINAL draft as it was before sharpening, verbatim. Never a reconstruction,
  unless its first line says `RECONSTRUCTION:` and why. Why: a draft rewritten after the fact
  carries the hindsight the eval exists to test, and the flow scores itself on an easier ticket.
- `miss.md`: what escaped, in one paragraph, with its proof (the failed re-test, the log line, the
  production event, where it was found). If the catch depends on the code as it was, name the
  commit here.
- `expected.md`: the finding a working flow must produce. Which lens or check should raise it, and
  the minimal wording that counts as a catch, in meaning, not in exact words.
- `request.md` (optional): the raw request as intake captured it, the reporter's own words. Without
  it the blind lens cannot run on this case, so add it whenever the source still exists.

## The run

When to run: whenever `intake` or `spec-sharpen` changes, and on every toolkit version bump.

1. For each case, run the full sharpening flow on `draft.md` in a scratch area (a temp folder, the
   sidecar only). Never on the live ticket, and never post to the tracker: an eval that writes
   trail comments onto a real ticket corrupts that ticket's history.
2. The sharpening run sees `draft.md`, `request.md` and the code, nothing else. Never `miss.md` or
   `expected.md`: a flow that has read the answer is not being tested. Where `miss.md` names a
   commit, run the code scan against a worktree at that commit.
3. A FRESH judge agent, not the one that sharpened, reads the run's findings with their triage fates
   and `expected.md`, and scores the case:
   - `caught`: the expected finding was raised and not killed in triage;
   - `missed`: it was never raised, or it was raised and then KILLED or DEFERRED away. A dismissed
     catch counts as a miss, because that is how the original escape usually happened.
4. Report, per run: the catch rate (caught / cases), and for each missed case the step
   `expected.md` names and the step, if any, that came closest.

Compare the catch rate with the last run. A drop is a regression in the process: fix the change or
record in the release notes why the lost case no longer matters.

## Adding a case

Every escape (a defect found after signing that the flow should have caught) is a candidate. Add
it when the miss is one a better lens or check could plausibly catch; a miss nobody could have seen
before production teaches the flow nothing and only drags the catch rate down.
