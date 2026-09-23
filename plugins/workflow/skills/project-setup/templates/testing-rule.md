# Testing: write the tests that catch real breakage, nothing else

Every test line is code someone maintains. A test earns its place only if a plausible future change
would break it AND that break would hurt a user, a customer or the data. The full method (what to
test, how to size it, how to audit an existing suite) is the `workflow:test-writing` skill; this
rule is the floor every agent follows.

## Write a test for

- A contract other code or a user relies on: an API response, a message or event payload, a tool
  or plugin signature, a shared function's meaning. Especially "unchanged for every other caller"
  promises.
- Anything that can lose or corrupt data: a sync or refresh that overwrites or prunes, a migration
  that transforms existing rows.
- <THE DOMAIN'S HIGH-STAKES AREAS, e.g. money, orders, availability, consent, permissions,
  isolation between accounts>.
- Date and time arithmetic, parsing of external input (third-party APIs, user uploads, model
  output, documents).
- A bug that actually happened: one regression test that fails on the old code.

## Do not write a test for

- Framework behaviour: that a model field exists, that a route or admin page is registered, that a
  form renders, that a migration applies, that the framework rejects an unrouted verb.
- Declarations, trivial getters, constants, logging calls, comments.
- Private helpers already exercised through the public path that uses them.
- The mock itself (asserting a mocked call happened, with nothing observable depending on it).
- The same rule again with a different value. Use <THE PARAMETRIZE IDIOM, e.g.
  `pytest.mark.parametrize`, `it.each`, table-driven tests> for variants.

## Shape

- One test per rule, named after the rule (`test_sync_never_overwrites_manual_edits`), so the file
  of test names reads as the spec.
- Assert the observable outcome, not the internal call sequence.
- Shared setup lives in a fixture; never copy the same ten lines of setup into each test.
- Mock only at the boundary (<THIS PROJECT'S BOUNDARIES, e.g. HTTP, the queue, email or SMS
  providers, model APIs>), never our own code.

## Size and coverage

- Guide: test lines about equal to code lines. Above 1.5 test lines per code line, the PR states why
  (for example: a new date-arithmetic module). `pr_test_stats.py`, shipped with
  `workflow:test-writing`, prints the ratio.
- Coverage is reported as DIFF coverage (changed lines the suite runs), never as a target to chase.
  An uncovered changed line that carries a rule is a gap; an uncovered `except` that only logs is not.
- Never delete or weaken a test to get green. Deleting a redundant test in an audit is allowed; say
  which rule the surviving test still covers.
