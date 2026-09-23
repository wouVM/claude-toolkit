# PR description template

Written for two readers, in this order. A reviewer who is not a developer (a product owner, a
founder) reads the four plain sections at the top and must be able to follow them without knowing
a module name. The developer reads on into Details. Before writing it, run `pr_test_stats.py` (next
to `workflow:test-writing`'s SKILL.md) from the branch's checkout, with `--run` where the suite is
Python and a `--category` for any part of the repo that reviews differently from code (config,
prompts, generated files). Quote its numbers; never estimate them. If it prints the undercount
WARNING, rerun before quoting.

The title is `[<ticket>] - <plain description>`: what changes, in words a user would recognise.
Never the branch name.

```
# [<ticket>] - <what changes, in words a user would recognise>

## Why
Two to four plain sentences: the problem a user or the business has today, and what is true after
this PR. Say what this PR does NOT change (e.g. "nobody sees a difference until the config change
ships").

## What changes
One line per group the change reaches: end users, customers, staff or operators, other customers
of a shared system, other teams. What each will notice, or "nothing". No module names, no error
codes.

## How it was tested
What was checked and against what (the test suite, staging, a real account), in plain words. Then
what could NOT be tested and why, and where it will be checked instead (for example "the vendor's
side only exists in production: checked after deploy with one real event").

## Review in this order (highest risk first)
Numbered. Each item: what to look at (a file and function, a screen, a behaviour), then ONE line
"Check: ..." naming what the reviewer must convince themselves of and who breaks if it is wrong.
Contracts other callers rely on and data-loss paths first; wiring and admin last.
Then a "Skim only:" line for declaration-only files.

---

## Details

### Size: what actually needs review
<the size table from pr_test_stats.py, plus a Review? column: Code yes, Migrations yes, each extra
category yes or no with the reason, Tests "skim the names">
About N lines to read. Diff coverage: X/Y (Z%). Test lines per code line: R (why, if above 1.5).

### Deploy
What the release needs: migrations and the release path that runs them, ship order against any
change that ships through another pipeline, anything a human must do by hand after the deploy.

### Verification
Suite result on the tip commit, the schema or migration check if the project has one, behavioural
checks run and against what, reviews run. Known flaky tests not touched here.

### Not in this PR
Named leftovers, one line each.
```
