---
name: build
description: >
  Dispatch a builder subagent to implement a spec, with the file allowlist, no-crawl rule, token
  budget and report-back prompt already wired, then review only the diff it returns. Load this
  whenever a design or spec session is about to become a build - the user says "/build", "go build
  it", "implement this", "ship it", or a plan the coordinator just wrote is ready to become code. It
  is the cheap path across the role boundary named in CLAUDE.md's cost discipline, and the thing to
  reach for INSTEAD of arguing with a role-fence hook that just refused an edit.
---

# /build - cross the role boundary without paying twice

ELI16 first: the coordinating model is expensive and good at judgment; the building model is the one that
should read source and write code. The problem is never that people disagree with that. The problem is that
doing it yourself takes zero setup and delegating takes a paragraph of prompt, so in the moment the wrong
path is always the cheap one. This skill is the paragraph, pre-written, so the correct path is the cheap one.

## The rule this serves

CLAUDE.md, cost discipline: **the coordinator DIRECTS and CHECKS, the builder EXECUTES, the scout EXPLORES.**
The boundary is the first EDIT to build code, and (where the project seeds it) `builder-model-guard.sh`
refuses to let a coordinator session cross it.

**The reads are the cost, not the edits.** A coordinator that has already read six source files has spent the
budget the delegation was supposed to save, and will then reason that delegating means paying twice. So reach
for this BEFORE reading build source, not after. The decision belongs at the moment the work turns into a
build, which is exactly the moment nothing announces.

## The steps

**1. The spec has to exist as a FILE, not as conversation.** A builder starts with none of your context. If
there is no spec yet, write one first (a heading, the outcome, the constraints, the files you expect to
change, the tests that must stay green). Markdown is never fenced, so the coordinator writes this itself. A
spec you cannot hand to a stranger is not finished. For a load-bearing spec, sharpen it with
`workflow:spec-sharpen` before dispatching.

**2. Name the allowlist.** List the exact files the builder may edit. If you cannot name them, the spec is
not ready and the honest next move is a scout pass (`explorer`, on a cheap model), not a builder.

**3. Dispatch.** One `Agent` call per independent chunk, in a single message when they do not depend on each
other. Use this plugin's `builder` agent, or the prompt template below:

> Implement the spec at `<path>`. Read it first; it is the contract.
>
> FILES YOU MAY EDIT (nothing else, and do not create new files outside this list without saying why):
> `<explicit list>`
>
> DO NOT crawl the repo. Read only: the files above, plus `<the 2-4 files the spec names as context>`. Never
> `node_modules/`. If you find you need a file outside this list, STOP and report what you need and why,
> rather than widening the read yourself.
>
> The house rules that bind this change: `CLAUDE.md`, and the trap book if this project keeps one (read the
> entries your change could repeat, and check your own work against them). Comment in this repo's register:
> state the CURRENT rule and why it is the rule, never narrate the change or point at what it replaced.
>
> WHEN A PIN MOVES: if an existing test asserts the old contract, update it to pin the NEW rule and say so in
> your report. Do not delete a test to make a suite green.
>
> RUN: `<the exact test commands>`. Report them as run, with real output. A failing suite is a finding, not
> something to work around.
>
> BUDGET: about `<N>`k tokens. If you are going past it, stop and report where you got to.
>
> REPORT BACK: the diff summary (file by file, what changed and why), the test results verbatim, every
> judgment call you made that the spec did not settle, and anything you could not do. Do not commit.

**4. Review the diff, not the files.** `git diff` is the coordinator's surface. Reading the builder's source
files back in defeats the whole exercise. Judge the shape, the taste calls, the honesty of the test report.

**5. Gate and land** the usual way: the independent code reviewers in parallel for a load-bearing diff, then
ONE taste gate (`workflow:springclean`, or `workflow:gemini judge` for a routine one), then commit.

## What stays the coordinator's, always

The spec. The allowlist. The taste calls and one-way doors. The diff review. The decision that the work is
done. Delegating execution is not delegating judgment, and a builder's report is evidence only once its
negatives have been checked: a subagent that says "all green" while a suite is red is a known failure mode,
so read the pasted output rather than the summary sentence.
