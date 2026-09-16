---
name: gemini
description: >
  Use Google Gemini 3.1 Pro (via the Antigravity CLI `agy`) as an independent
  second-opinion reviewer and judge, distinct from codex, on a par with it. Four
  modes: review (a full code review of a commit range with a PASS/FAIL gate, run
  ALONGSIDE your other reviewers, not instead of them), challenge (a rigorous
  stress-test that hunts the edge cases and failure modes a change mishandles),
  consult (a resumable back-and-forth where Gemini can ask Claude Code questions
  about WHY), and judge (does NOT re-check correctness; judges whether it was the
  RIGHT work: proportionate, no hand-rolling, honest, faithful to the project's
  CLAUDE.md and ledgers, driven by a per-project rubric at .claude/gemini-judge.md).
  Gemini reads the repo itself; you point it at commits, you do NOT paste code.
  Invoke on "gemini review", "gemini challenge", "gemini judge", "ask gemini", or
  "second opinion from gemini". A different AI vendor, a genuinely independent voice.
allowed-tools: Bash, Read, Write, Glob, Grep, AskUserQuestion
---

# /gemini - Gemini 3.1 Pro second opinion (via agy)

You are running the `/gemini` skill. It wraps the Antigravity CLI (`agy`, Google's
successor to the retired Gemini CLI) to get an independent second opinion from
Gemini 3.1 Pro. It is an outside voice that challenges assumptions and catches what
you missed, from a different vendor. If this machine also has `/codex` (or another
independent reviewer), `/gemini review` and that reviewer are PEERS: run BOTH, in
parallel, and land only when both agree. `/gemini judge` is an ADDITIONAL
taste-and-honesty gate that a correctness reviewer does not cover, not the only
thing Gemini is for.

Gemini here is a strong, direct reviewer. Present its output faithfully, not
summarized. When it disagrees with another reviewer or with you, surface the
disagreement; cross-model agreement is a recommendation, not a decision, and the
user decides.

Auth uses the user's Gemini Pro subscription through `agy`'s own login (no API
key, no per-token billing). Reviews run on `Gemini 3.1 Pro (High)` by default.

---

## Step 0: Preflight (run first)

```bash
AGY_BIN=$(command -v agy || echo "")
if [ -z "$AGY_BIN" ]; then
  echo "AGY_NOT_FOUND"
else
  echo "FOUND: $AGY_BIN ($(agy --version 2>/dev/null | head -1))"
fi
```

If `AGY_NOT_FOUND`: stop and tell the user:
"Antigravity CLI not found. Install it: `curl -fsSL https://antigravity.google/cli/install.sh | bash`, then run `agy` once to sign in with your Google (Gemini Pro) account."

Auth is checked implicitly by the first real call. If a call returns an
auth/login error instead of an answer, stop and tell the user to run `agy`
interactively once to sign in, then re-run this skill. The token can lapse between
runs; if a first call fails auth, a quick retry often refreshes it before you give up.

Model choice (default is correct for review; change only on request):
- `Gemini 3.1 Pro (High)` - default. The strong reviewer. Use for review/challenge/judge.
- `Gemini 3.1 Pro (Low)` - faster, cheaper Pro. Use when the user wants speed.
- `Gemini 3.5 Flash (High)` - fastest, weakest. Only for trivial/large-context passes.
- Do NOT default to the Claude models `agy` also exposes: using Claude here would
  defeat the point of an independent, non-Claude second opinion.

Set once for the whole run (and always run agy FROM the repo/worktree root, so its
tools see the code):

```bash
GEMINI_MODEL="Gemini 3.1 Pro (High)"
GDIR=$(mktemp -d "${TMPDIR:-/tmp}/gemini-XXXXXX")
cd "$(git rev-parse --show-toplevel)" || true
echo "MODEL: $GEMINI_MODEL"; echo "GDIR: $GDIR"; echo "REPO: $(pwd)"
```

---

## How agy is invoked: repo access, point it at commits, never paste code

Gemini reviews by READING THE REPO ITSELF. You point it at a commit range; you do
NOT copy the diff or file bodies into the prompt. This is the whole reason for the
`--dangerously-skip-permissions` flag: it auto-approves agy's tool calls (read
files, run `git`) so headless print mode does not stall on a permission prompt (an
unapproved tool call is the classic silent hang). The user has explicitly opted in
to this for the review path.

The canonical call (used by every mode, first turn):

```bash
timeout 2100 agy --model "$GEMINI_MODEL" --print-timeout 30m --dangerously-skip-permissions \
  -p "$(cat "$GDIR/turn.txt")" >"$GDIR/out.txt" 2>"$GDIR/err.txt"; echo "exit: $?"
```

And to CONTINUE the same conversation (the talk-back loop, `-c`):

```bash
timeout 2100 agy -c --model "$GEMINI_MODEL" --print-timeout 30m --dangerously-skip-permissions \
  -p "$(cat "$GDIR/turn.txt")" >"$GDIR/out.txt" 2>"$GDIR/err.txt"; echo "exit: $?"
```

Every prompt you write to `$GDIR/turn.txt` should:
- Name the exact scope as a git ref range (e.g. `git diff <BASE>..HEAD`, a
  `<sha1>..<sha2>` range, or a single `git show <sha>`) and tell Gemini to run it
  and read whatever changed files, callers, or context it needs.
- Tell it to skip Claude Code plumbing (`.claude/`, `agents/`, `~/.claude/`): those
  are harness definitions for a different AI system and only waste its time. The one
  exception is `.claude/gemini-judge.md` in judge mode, which you hand it on purpose.
- Carry the ASK-CC protocol (below) so it routes questions of INTENT ("why did you
  do X", "what is the constraint on Z") back to you, since those live in your head
  and this session's history, not in the files.

Never truncate on Gemini's behalf: it fetches its own context, so you do not have a
size budget to manage. Just give it the range and let it read.

---

## The talk-back + resume loop (the core mechanism)

This is what makes `/gemini` more than a one-shot: Gemini can ask Claude Code
questions (why did you do X, what is the constraint on Z, what did the test show)
and get answers, across turns, with full context retained. `agy -c` continues the
most recent conversation; it is verified to carry context across separate headless
`-p` calls. Because Gemini reads files itself, ASK-CC is mostly for INTENT and
things not in the repo (a test result, a product constraint, the reason a tradeoff
was made), not for fetching files.

Append this protocol block to the FIRST prompt of every mode:

> ASK-CC protocol: You can read the repo yourself. If you need something that is NOT
> in the code (the reason a change was made, a constraint, a test result, product
> intent), put each request on its own line starting with `ASK-CC:` and stop. I will
> answer and continue this same conversation. When you are fully done and need
> nothing more, end your message with a single final line: for review use
> `VERDICT: PASS` or `VERDICT: FAIL`; for challenge use `VERDICT: <one-line risk
> summary>`; for consult use `DONE`. Do not emit a VERDICT/DONE line in the same
> message as any ASK-CC line.

Driver loop (you, Claude Code, run this):

1. Write the first prompt (scope + task + ASK-CC protocol) to `$GDIR/turn.txt`, then
   make the canonical first-turn call above.
2. Read `$GDIR/out.txt`. Scan for lines starting with `ASK-CC:`.
   - If there are ASK-CC lines: answer each one truthfully from this session's
     knowledge of WHY (and run any check it asked for). Write the numbered answers to
     `$GDIR/turn.txt`, then make the `-c` continue call. Repeat step 2.
   - If there is a `VERDICT:` / `DONE` line and no ASK-CC line: the loop is done.
3. Cap the loop at 6 rounds. If Gemini is still asking after 6 rounds, stop and
   report where it got stuck rather than looping forever.

Notes:
- `agy -c` continues the most recent `agy` conversation. Within one `/gemini`
  invocation you drive `agy` serially, so "most recent" is always this thread.
- For robustness across interleaved runs, conversations also live in
  `~/.gemini/antigravity-cli/conversations/` and can be resumed by id with
  `agy --conversation <id> --dangerously-skip-permissions -p "..."`. Prefer `-c`.
- `agy` prints progress to stderr (captured in `$GDIR/err.txt`); the actual answer
  is on stdout (`$GDIR/out.txt`). If stdout is empty, read `err.txt` for the cause.

---

## Failure modes: an AUTH stall vs a CONTENT-POLICY refusal vs a RESPONSE timeout

Three different non-answers all look like a "failed" run. Read `$GDIR/out.txt` and
`$GDIR/err.txt` and tell them apart, because the fixes differ:

- **Auth stall.** A printed Google / Antigravity login URL plus `authentication timed
  out` (a ~60s hang) means agy could not load its cached OAuth token. `-p` is already
  the correct non-interactive form; it cannot conjure a token, and agy has no
  non-interactive `login`. Do NOT retry or fiddle flags. On a desktop machine the
  token usually lives in the OS keychain; on a headless box it may sit in a keyring
  that must be unlocked before agy can read it (if this machine has a keyring-unlock
  helper, run it and retry ONCE). If the stall persists, the Google session itself
  expired: the USER must run `agy` interactively once to re-sign-in (it caches the
  token), after which headless works again. In a headless / background run, report
  the auth stall, proceed with your other reviewer alone for now, and flag that the
  owner should re-auth agy and re-run `/gemini review` before a load-bearing landing.

- **Content-policy refusal.** Gemini DOES answer, but the answer is a refusal along
  the lines of "I cannot help with adversarial reviews / vulnerability scanning /
  finding exploits." This is NOT an auth or a code problem: it is the PROMPT FRAMING.
  Gemini's safety filter reads "break this / attack it / find vulnerabilities to
  exploit / assume the author was careless" as a request for offense. The fix is to
  RE-ISSUE the SAME scope as a plain engineering review: strip every red-team word
  (break, attack, adversarial, exploit, vulnerability, "careless") and ask, in
  PR-review terms, "where does this change behave incorrectly or mishandle untrusted
  input." The prompts in this skill are already written that way; if you hand-write a
  one-off gemini prompt, keep that framing. Re-issue once with the review framing
  before concluding gemini is unavailable. A code review is a legitimate ask; a
  vuln-hunt reads as one that is not.

- **Response timeout: `Error: timeout waiting for response`, empty stdout, NO login URL.**
  agy's `--print-timeout` flag defaults to FIVE MINUTES and silently kills any
  headless run whose agentic repo-read outlasts it - which every serious multi-file
  review does. The canonical calls above pass `--print-timeout 30m`; if you see this
  error, the flag is missing from the call, not the scope from the prompt. (Scoping
  the prompt down treats the symptom: smaller reads finish under 5m. Scoping is
  still fine for FOCUS; it is not the fix for this error.) If a run outlasts even
  30m, raise the flag and the outer `timeout` together, or split the review - and
  only then consider the vendor unavailable.

## Step 1: Detect mode

Parse the user's input:

1. `gemini review` (optionally with instructions) -> Review mode (Step 2A)
2. `gemini challenge` (optionally with a focus) -> Challenge mode (Step 2B)
3. `gemini judge` (optionally with a scope) -> Judge mode (Step 2D)
4. `gemini` with no clear verb but a diff exists -> ask which they want (review / challenge / judge / consult)
5. Anything else after `gemini` -> Consult mode (Step 2C), the text is the prompt

If bare `gemini` and a diff exists against the base branch, ask via
AskUserQuestion: A) Review the diff, B) Challenge the diff, C) Judge the work
(proportion + honesty), D) Consult. If no diff and no prompt, ask what they want
Gemini to look at.

Compute the review base + range, then PASS THE RANGE to Gemini, do not build a
patch file to paste:

```bash
BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
[ -z "$BASE" ] && BASE=$(git rev-parse --verify origin/main >/dev/null 2>&1 && echo main || echo master)
# The range Gemini will run itself:
RANGE="origin/$BASE...HEAD"
git rev-parse --verify "origin/$BASE" >/dev/null 2>&1 || RANGE="$BASE...HEAD"
git diff "$RANGE" --stat | tail -1   # just so YOU know the size; Gemini reads it itself
echo "RANGE: $RANGE"
```

If HEAD is based off an unpushed local branch (so `origin/$BASE` is far behind and
the range would include unrelated work), scope the range to your own commits
instead (e.g. `<your-base-sha>..HEAD`) and say so.

---

## Step 2A: Review mode

Goal: an independent code review of a commit range with a hard PASS/FAIL gate, run
as a PEER of any other independent reviewer this machine has (not a replacement).
Land only when all pass.

First prompt to Gemini (scope + this + ASK-CC protocol), written to `$GDIR/turn.txt`:

> You are a meticulous senior engineer reviewing a teammate's pull request before it
> merges, with full read access to this repo. Read the change `git diff <RANGE>` (run
> it yourself, then read the changed files and their callers as needed) and report
> what would go wrong in production: correctness bugs, broken contracts, missing edge
> and error cases, and input-handling / auth / data-exposure mistakes. Ignore
> `.claude/`, `agents/`, and `~/.claude/` (Claude Code harness plumbing). Be direct
> and terse. Cite file and line. Rank findings by severity (P0 blocker, P1
> should-fix, P2 nit). If you need to know WHY a change was made or a fact not in the
> code, use ASK-CC. End with `VERDICT: PASS` (no P0/P1) or `VERDICT: FAIL` (has
> P0/P1).

Substitute the real `<RANGE>`. Then run the talk-back loop. When it finishes:
- Present Gemini's findings verbatim, grouped by severity.
- State the gate outcome plainly: PASS or FAIL, and if FAIL, the P0/P1 list that
  must be fixed. Do not soften it.
- This is a landing gate on a par with your other reviewers: treat a Gemini FAIL as
  blocking, and run every reviewer you have.

Reasoning effort: `Gemini 3.1 Pro (High)` is the default and is the "high effort"
tier for review. No extra flag needed.

---

## Step 2B: Challenge mode

Goal: a rigorous stress-test. Gemini hunts the edge cases and failure modes the
change mishandles instead of signing off on the happy path. This is hard-nosed
engineering review, not a security red-team (see "Failure modes" for why the framing
matters): the job is to find where the code behaves INCORRECTLY, not how to exploit it.

First prompt (scope + this + ASK-CC protocol):

> You are a demanding senior engineer stress-testing a teammate's change before it
> merges, with full read access to this repo. Read the change `git diff <RANGE>` (run
> it, read what you need) and find where it behaves incorrectly: the inputs, states,
> race conditions, and unstated assumptions that make it produce a wrong result,
> crash, or corrupt data. Give a concrete failure scenario for each concern (inputs
> -> wrong result or crash). Do not assume the happy path; walk the edge and error
> paths. Ignore `.claude/` and `agents/`. Use ASK-CC if you need the reason behind a
> design choice before you can assess it. End with `VERDICT: <one-line residual risk>`.

Run the talk-back loop. Present every failure path faithfully, most severe first,
each with its concrete repro. Do not editorialize the risk away.

---

## Step 2C: Consult mode

Goal: an open, multi-turn conversation with Gemini Pro, where either side can ask
the other questions. This is the mode for "I want Gemini to do a specific thing and
be able to ask me why I did what I did."

First prompt (the user's actual request + the repo access note + any context only
you hold + ASK-CC protocol, ending instruction `DONE`). Gemini can read the repo
itself; tell it what to look at (a path, a range, a subsystem). Then run the
talk-back loop, answering every ASK-CC honestly, until Gemini emits `DONE`.

This mode is deliberately general. When the user gives you the specific task they
want Gemini to perform, put it in this first prompt; the ASK-CC loop handles the
back-and-forth automatically.

---

## Step 2D: Judge mode

Goal: judge whether this was the RIGHT work (proportion, honesty, fidelity to the
project's principles), NOT whether the code is correct (review mode and your other
reviewers own correctness). This is the mode to run OFTEN: after each milestone or
feature.

1. Load the project rubric: read `<repo-root>/.claude/gemini-judge.md`. If present,
   it IS Gemini's system prompt for this mode (it encodes the project's principles
   and how its ledgers work), so paste its text into the first prompt. If absent,
   tell the user "no .claude/gemini-judge.md in this repo; run a generic judge
   (proportion, no hand-rolling, no missed simplification, honesty, no drift)?" and
   only proceed on their yes. (The `project-setup` skill in this plugin seeds a
   rubric template.)

2. Point Gemini at the scope + evidence (it reads them itself):
   - What is being judged: a range (default `<RANGE>` from Step 1), a named commit
     range, OR a plan/spec file the user points at. Judge can run on a PLAN, not
     only shipped code. Name the exact ref or path.
   - Tell it to read the KLOC delta itself (`git diff <RANGE> --stat`).
   - Tell it to read every current-state ledger the rubric names that EXISTS (it
     opens each present, skips absent) - typically the trap book (`TRAPS.md`), the
     deferral ledger (`DEFERRED.md`), and the fault catalogue
     (`FAULT-CATALOGUE.md`). For the trap book: judge the diff against its shapes
     AND hunt shapes it does not hold.
   - Recurrence context: tell it to run `git log --oneline -20` on the ledger paths
     that exist, so it can see whether a fault repeats.

3. Build the first prompt: the rubric text (system prompt) + the scope/range to
   judge + the list of ledgers and git commands to read + the ASK-CC protocol.
   Instruct Gemini to end with a one-line verdict PER dimension, an overall
   `JUDGE: SOUND` or `JUDGE: CONCERNS` (list the must-address items), and any new
   fault as a `LOG-FAULT:` block in the catalogue's entry format.

4. Run the talk-back loop (see "The talk-back + resume loop"): answer every ASK-CC
   from this session's knowledge of WHY, until Gemini emits its verdict. Do not let
   it judge intent on a guess.

5. Present the judgment faithfully (per dimension + overall). If Gemini emitted
   `LOG-FAULT:` blocks, propose appending them to the fault catalogue (to Open
   faults, or the recurring-pattern watchlist if it is a repeat). Log only after the
   user agrees, and keep the catalogue current-state: remove a fault when resolved,
   git tracks the history.

---

## Presenting results

- Faithful, not summarized. Quote Gemini's own words for findings and verdicts.
- Attribute clearly: "Gemini 3.1 Pro says ...". It is a second opinion, not ground
  truth. If it conflicts with another reviewer or the code, say so and let the user
  decide.
- Report the model used and the number of talk-back rounds it took.
- Clean up: `rm -rf "$GDIR"` at the end (the agy conversation persists on its own
  in ~/.gemini for later `-c` resume if needed).

## Voice

Direct, concrete, technical. Lead with the finding. Name files, lines, commands,
and failure scenarios. No corporate hedging, no hype, no em-dashes. Sound like a
builder relaying another sharp builder's read of the code.
