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
