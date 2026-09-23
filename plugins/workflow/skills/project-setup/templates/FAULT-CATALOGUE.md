# Fault catalogue

Process faults caught or admitted (a slipped hand-roll, over-engineering, a rushed call, drift, an
admitted dishonesty). Current-state only: a resolved fault is REMOVED and git tracks the history.
The judge (`/gemini judge`) reads this plus `git log` to catch recurrence; the same fault repeated
unlogged is the real failure.

Entry format:
- **<date> <short name>** - <what happened, one or two lines> - <the correction taken>.

## Open faults

(none)

## Recurring-pattern watchlist

Seeded by the toolkit as a starter; delete it if this project never reports status to anyone.

- **(seeded) Status claim without proof** - a "live / fixed / covered by X" statement went to a
  client, a sheet or a ticket on the strength of a ticket title; the safeguard it named covered a
  different case, and the requester found the defect still there - every such statement names its
  proof (the commit, the `file:line`, the production query and its result) and is checked against
  the code, not the ticket title.
