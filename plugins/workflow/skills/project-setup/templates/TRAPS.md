# TRAPS - the trap book

ONE file holds the SHAPES this project has already fallen into. Read it while you work and check
your own work against it; if you have done something similar to an entry, reflect and remediate.

The rules (they keep the book usable):
- An entry records a FAILURE SHAPE, never a receipt: writing a shortcut down does not pay for it.
- This is NOT a TODO list. A thing that still has to be fixed is a tracked issue; the book keeps
  only the shape.
- A genuinely NEW shape earns a new entry. A RECURRENCE sharpens the entry it matches (tighten the
  wording, note that it recurred) and adds no incident. A fixed one-off is just fixed.
- Never append a round's diary. The instrument is readability, not length: if one shape appears
  five times, consolidate BEFORE adding.
- A shape that is true of projects in general goes upstream too: propose its general form for the
  toolkit's starter book (springclean's "is this general?" step), so the next project starts with it.

## The shapes

<!-- Entry format:
## <N>. <short name for the shape>
<2-5 lines: the shape in the abstract (what the failure looks like from the outside), then the
tell (how you catch yourself doing it). No incident log, no dates, no blame.>
-->

The entries below ship as STARTER shapes: they recur across projects. Keep the ones that can apply
here, delete the rest, and renumber.

## 1. Done in the tracker, switched off in production
The ticket is Done and the code is in the release, but the feature was never switched on: the config
row is missing, the secret is not set, the external side was never connected, so it fails quietly.
Why: a webhook receiver shipped and was never connected on the vendor side, and nobody noticed for
weeks. The tell: "done" was declared from the merge, not from one real event going through in
production. Guard: a ticket closes on verified activation, plus a periodic read-only production
health census listing features switched off, integrations without a credential, templates without
an external id or approval, and webhooks with zero deliveries.

## 2. A file-copy deploy reverts a hand edit
The deploy copies files from the released branch over the live config, so an edit made by hand in
the live system and not merged before the next release tag is silently overwritten by a green
pipeline. Why: a hand-applied fix went live, the next release restored the old file, and the
pipeline reported success. The tell: any "I changed it directly in the admin / console" without a
matching merged commit. Guard: hand edit means merge before the next tag, and a release preflight
that diffs live config against the branch being released and refuses the tag when live is ahead.

## 3. The same block, copied N times, drifts
One shared rule or config block lives as a copy in many places (per customer, per environment, per
service), and each fix lands in the few copies someone touched. Why: the same class of fix was
applied a third time, to three copies out of thirty. The tell: a fix whose instructions say "and
repeat for each of the others". Guard: one blueprint with per-instance overrides and a regeneration
command; the third copy of a block, or the third fleet-wide fix of one class, is a refactor ticket,
not another port.

## 4. A "flaky" local test that is really the database's mount
Local tests fail intermittently with permission-denied errors under the database's data directory,
and pass on CI. Why: the local database kept its data directory on a VM bind mount, whose file
ownership and permissions shift under load; a named container volume does not do this. The tell:
the errors name files inside the data directory, never the test's own code. Guard: keep database
data on a named volume, never a bind-mounted host directory.

## 5. Green is a claim, not a proof
"All green" came from mocked tests, or from an agent's summary nobody read, and the live path was never
run. The tell: a "done", "fixed" or "live" with nothing attached. Guard: every such word cites its
proof (the pasted output, the commit, the file:line), and a mocked pass is never reported as a live one.

## 6. A test that passes with the feature deleted
The test asserts on a mock, a constant or its own setup, so it stays green when the code it names is
removed. The tell: you cannot say which line of the feature makes it fail. Guard: delete or break the
feature once and watch the test go red before trusting it.

## 7. Parallel agents leave contradictions
Several agents change one rule across many files at once; each edits its own file and none sees the
others, so the old wording survives somewhere. Guard: after any multi-agent rollout, grep the whole set
for the old wording and the old names before calling it done.

## 8. Hand-typed timestamps
A time written into a status file, a ticket or a handover from memory was hours off, and the next reader
trusted it. Guard: every timestamp comes from `date`, never typed by hand.

## 9. A broad `pkill -f` kills the machine
A pattern loose enough to match the dev server also matched every other app running, and they all died.
The tell: a `pkill -f` or `killall` with a short or generic pattern. Guard: stop a server by its port
(`lsof -ti :<port>`) or its PID, never by a pattern.

## 10. A worktree is not a full checkout
A fresh worktree has the code but not the untracked `.env`, shares the main checkout's ports and points
at the same test database, so it fails to start or two runs corrupt each other. Guard: give every
worktree its own `.env` link, its own ports and its own test database when it is created.

## 11. curl of the HTML is not the UI
The page renders client-side, so curl returns the shell and a check on it passes while the screen is
broken, or fails while the screen is fine. Guard: check UI in a real browser (the browser tooling, both
widths), never by fetching the HTML.

## 12. `codex exec` hangs in a background shell
Run in the background, `codex exec` waits on stdin that never closes, and the run sits until a timeout.
Guard: always redirect its input, `codex exec ... < /dev/null`.
