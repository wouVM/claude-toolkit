# PR description template

Written for the reviewer, not for the author: what they must check, in what order, and what they
can skip. Before writing it, run `pr_test_stats.py` (next to `workflow:test-writing`'s SKILL.md)
from the branch's checkout, with `--run` where the suite is Python and a `--category` for any part
of the repo that reviews differently from code (config, prompts, generated files). Quote its
numbers; never estimate them. If it prints the undercount WARNING, rerun before quoting.

```
# [<ticket>] - <what changes, in words a user would recognise>

## Why
Two to four sentences: the problem a user has today, and what is true after this PR. Say what this
PR does NOT change (e.g. "nobody sees a difference until the config change ships").

## Size: what actually needs review
<the size table from pr_test_stats.py, plus a Review? column: Code yes, Migrations yes, each extra
category yes or no with the reason, Tests "skim the names">
About N lines to read. Diff coverage: X/Y (Z%). Test lines per code line: R (why, if above 1.5).

## Review in this order (highest risk first)
Numbered. Each item: the file and function, then ONE sentence "Check: ..." naming the property the
reviewer must convince themselves of, and why it matters (who breaks if it is wrong). Contracts
other callers rely on and data-loss paths first; wiring and admin last.
Then a "Skim only:" line for declaration-only files.

## Deploy
What the release needs: migrations and the release path that runs them, ship order against any
change that ships through another pipeline, anything a human must do by hand after the deploy.

## Verification
Suite result on the tip commit, the schema or migration check if the project has one, behavioural
checks run and against what, reviews run. Known flaky tests not touched here.

## Not in this PR
Named leftovers, one line each.
```
