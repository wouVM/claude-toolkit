---
name: test-writing
description: >
  Write or audit tests so a change gets the few tests that catch real breakage, not a wall of test
  lines. Two modes. WRITE - after a builder implemented a change, a separate agent writes its tests
  from the acceptance criteria and the diff. AUDIT - grade the tests an existing branch or PR added,
  test by test (keep / merge / shrink / cut / gap), and report the lines that can go. Use whenever
  tests are about to be written for a ticket or spec, when a PR's test lines dwarf its code lines,
  or when asked "are these tests overkill", "review the tests", "trim the tests". Ships
  pr_test_stats.py, which prints a branch's size split, test-to-code ratio and diff coverage for a
  PR description.
argument-hint: "write|audit <ticket-or-branch> <worktree-path>"
---

# /test-writing - tests that earn their lines

This skill runs in its own agent, never inside the builder. The builder knows how the code works
and tests that; a separate writer tests what the ticket promised, which is what a reviewer and a
future change actually need.

`pr_test_stats.py` sits next to this SKILL.md. Run it from inside the checkout being measured.

## The one question

For every test, written or existing, answer: **which plausible future change makes this test fail,
and would that change hurt a user, a customer or the data?** Name the change concretely ("someone
drops the ownership check in `upsert`"). If you cannot name one, the test does not earn its lines.

## The floor

If the repo was seeded by `workflow:project-setup`, this rule lives at `.claude/rules/testing.md`,
filled in with the project's own high-stakes areas and boundaries; where the two differ, the repo's
file wins. Otherwise this section is the rule. The risk ladder below is what to test; this is how.

- One test per rule, named after the rule (`test_sync_never_overwrites_manual_edits`), so the file
  of test names reads as the spec.
- Assert the observable outcome (return value, stored row, API response, payload handed to the
  boundary mock), not the internal call sequence.
- Shared setup lives in a fixture; never copy the same ten lines of setup into each test.
- Mock only at the boundary (HTTP, queues, email or SMS providers, model APIs, auth providers),
  never the project's own code.
- Variants of one rule are one parametrized test (`pytest.mark.parametrize`, `it.each` /
  `test.each`, a table-driven loop), not new functions.
- Guide: test lines about equal to code lines. Above 1.5 test lines per code line, the PR states why.
- Coverage is reported as DIFF coverage (changed lines the suite runs), never as a target to chase.
  An uncovered changed line that carries a rule is a gap; an uncovered `except` that only logs is not.
- Never delete or weaken a test to get green. Deleting a redundant test in an audit is allowed; say
  which rule the surviving test still covers.

## Risk ladder (spend tests top-down, stop when the rest is framework)

1. Contracts other code or users rely on: API responses, message or event payloads, tool
   signatures, a shared function's meaning, "unchanged for every other caller" promises.
2. Data loss or corruption: overwrite, prune, cascade, migrations that transform rows.
3. The domain's high-stakes areas: money, orders, availability, consent, permissions, isolation
   between accounts.
4. Date/time arithmetic, parsing of third-party, document, upload or model input.
5. A bug that actually happened (one regression test, failing on the old code).
6. Everything else: usually nothing, or one happy-path smoke test for a new public entry point.

Never: framework behaviour, declarations, admin or route registration, a form merely rendering, a
migration merely applying, logging, private helpers already reached through the public path,
asserting a mock was called when nothing observable depends on it.

## Mode WRITE

Inputs: the acceptance criteria, the builder brief or spec, the diff (`git diff <base>...` plus
uncommitted changes), the worktree path. You may edit only test files and test fixtures.

1. List the rules the change introduces, one line each, each tagged with its ladder rung. An
   acceptance criterion usually yields one to three rules. Drop rung-6 rules unless it is a new
   public entry point.
2. For each rule: one test, named after the rule, at the single layer where the rule is observable
   (usually the public entry point), not again at every layer it passes through. Reuse the repo's
   existing fixtures, factories and `conftest.py` / setup files first; add a shared fixture before
   copying setup twice.
3. Assert what an outsider can observe; mock only at boundaries.
4. Run the tests you wrote, then `pr_test_stats.py --base <base>` for the ratio. Above 1.5 test
   lines per code line: cut or merge until below, or state in the hand-back which rung-1/2 rules
   justify the size.
5. Hand back: the rule list with the test that guards each, the ratio, and any rule you could not
   test and why.

## Mode AUDIT

Inputs: a branch or PR, a worktree checked out at it, the ticket or spec (for what was promised).
You do NOT edit anything; the report is the deliverable. The caller decides what to cut.

1. `pr_test_stats.py --base <base>` for the size split. Read the acceptance criteria.
2. Read every test the branch ADDED or changed (not pre-existing tests). For each, give one row:
   - **KEEP**: the rung, and the concrete future change it catches.
   - **MERGE**: which other tests it collapses into (usually one parametrized test), lines saved.
   - **CUT**: why (framework / duplicate of test X / mock-only / private helper / no nameable
     breakage), lines saved.
   - **SHRINK**: a keeper whose setup or assertions are bloated; what to lift into a fixture.
3. List **GAPS**: rules in the diff on rungs 1 to 3 that no test guards. Short; a gap matters more
   than ten cuts.
4. Before recommending a CUT, confirm the rule it covers is still covered by a KEEP, or is on
   rung 6. Cutting the only test of a rung 1-3 rule is not allowed.
5. Write the report where the project keeps review notes (a `docs/` folder, or a comment on the
   ticket if it keeps none):
   - top: current test lines, lines after the recommended changes, ratio before and after
   - the per-file table of rows above, grouped KEEP / MERGE / SHRINK / CUT
   - the GAPS list
   - one paragraph: the pattern behind the excess, so the next build avoids it
6. Do not run the full suite. Read, reason, and use targeted test runs only when a claim depends
   on it (for example "test X and Y exercise the same branch": check with coverage on those two).

## pr_test_stats.py

- `--base` defaults to `$PR_BASE`, else `origin/main`. Pass the branch the PR targets.
- `--category NAME=REGEX` (repeatable) adds a row for paths that review differently from code,
  e.g. `--category 'Config=^config/'`. Tests are always classified first.
- `--run` runs a Python suite under coverage (`$PYTEST`, default `pytest`, plus `$PYTEST_ARGS`
  such as `-n auto`) and prints diff coverage; `--cov-json` reuses an existing coverage.py report.
- JavaScript and other runners: the size split and ratio work unchanged. Diff coverage reads
  coverage.py JSON only, so for those suites run the runner's own coverage (`vitest --coverage`,
  `jest --coverage`, `go test -cover`) and quote its number for the changed files, or say it was
  not measured. Never estimate it.

Its output goes into the PR description; the template for that is
`workflow:pickup`'s `templates/pr-description.md`.

## Calibration

A healthy change on rungs 1-3 sits around 1 test line per code line. A new pure-logic module
(date arithmetic, parsing) may justify 1.5 to 2. Admin wiring, serializers and view plumbing
rarely justify more than one test per behaviour a user can see. Diff coverage in the high 80s or
90s is normal and fine; chasing the last uncovered `except` that only logs is not.
