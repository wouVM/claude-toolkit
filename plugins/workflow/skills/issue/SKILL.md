---
name: issue
description: >
  File a captured idea, escalation, bug, task, or design thought as a GitHub issue in the current
  repo, auto-classified with a label and cross-linked to related open issues, so a loose thought
  becomes a tracked `gh#N`. Classifies the item (idea / escalation / bug / task / architecture /
  escape), asks if the category is unclear, and proposes a merge or link with duplicates BEFORE
  creating. An `escape` (a defect found after a ticket was signed) records the flow step that should
  have caught it; `/issue escapes` counts them per step. Triggers on "/issue", "file this", "open an
  issue for this", "capture this", "track this idea", "log this escalation", "this escaped", "count
  escapes", "amend gh#N by ...". NOT for reviewing code, and NOT for external bug trackers (escapes
  excepted).
allowed-tools: Bash, Read, Write, AskUserQuestion
---

# /issue - capture something as a tracked, related GitHub issue

Turn a loose idea / escalation / bug / task into a GitHub issue with a `gh#N` handle, so it
stops living only in a chat and joins the tracked web of work. Two jobs the raw `gh issue
create` does not do, and the reason this skill exists: (1) it CLASSIFIES the item, and (2) it
finds how the item RELATES to what is already filed and links it, so the web builds itself
instead of every capture landing as an orphan. The text is filed AS-IS; the skill authors only
the title, the label, and the links (and, for an escape, its three-line record).

## Step 0: Mode and tracker, then the GitHub preflight

`/issue amend <ref> ...` (or "amend / add to / correct gh#N") adds to an existing issue: see
"Amend" below. `/issue escapes` (or "count escapes", "which step leaks") files nothing: see "Count
escapes" below. Otherwise file a NEW issue (Steps 1 to 5).

Then read `tracker.kind` from `.claude/pickup.json` if the file exists. Absent, or `github`, means
everything below is GitHub-backed. Why this comes first: an escape follows the project's tracker,
and a project without `gh` must not stop at a GitHub check it will never use.

Run the preflight below only for GitHub-backed work. On another tracker, counting escapes and filing
an escape skip it; filing anything else and amending still go to GitHub, so for a new item run the
preflight once Step 2 has classified it as not an escape.

```bash
command -v gh >/dev/null 2>&1 || echo "GH_MISSING"
gh auth status >/dev/null 2>&1 || echo "GH_UNAUTHED"
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
echo "REPO: ${REPO:-UNRESOLVED}"
```

- `GH_MISSING`: stop, tell the user to install the GitHub CLI (https://cli.github.com) then `gh auth login`.
- `GH_UNAUTHED`: stop, tell the user to run `gh auth login`.
- `REPO: UNRESOLVED`: not in a GitHub-recognized repo. Ask the user for the `owner/repo`.

Everything below uses `gh` so it is portable. If this session also has the `github` MCP
(`mcp__github__*`) connected, you MAY use `mcp__github__issue_write` for a native
`state_reason:"duplicate"` + `duplicate_of` close (a real, queryable GitHub relationship) instead
of the `gh` fallback; prefer it when present, but never assume it is.

## Step 1: Get the content

In order: a file if the argument is a path or `@path`; the text following `/issue`; the
conversation content the user clearly means ("file that"); else ask "what should I capture?".
Hold the raw content UNCHANGED - it is the body's core. Do not summarize or reflow it.

## Step 2: Classify (with a bounce-back if unsure)

HARD RULE first: **NEVER file an item that is already done / solved / resolved.** Git history
is its record; a closed issue for finished work is noise. If asked to file something
already handled, say so and skip. The one exception is an `escape`: file it even when the defect is
fixed, and close it on filing if nothing is left to do. Why: its record is about the step that
leaked, and fixing the defect does not fix the step.

Pick ONE label from the FIXED set (deliberately small - do NOT invent new labels, and NO cross-cutting
or area/subsystem labels): `idea` (a suggestion / design thought / feature wish), `escalation` (a
user-filed "this behaved wrong"), `bug` (a concrete defect), `task` (a discrete unit of work),
`architecture` (an open architecture decision to settle), `escape` (a defect found AFTER a ticket was
signed that the flow should have caught earlier: a failed re-test by the requester, a staging failure,
a production failure). These overlap on purpose (an escalation is very often really an idea) - pick
the dominant intent. An escape is also a bug; pick `escape` whenever there is a signed ticket it
escaped from, because only that kind gets counted per step. (One more label, `epic`, exists on the
same KIND axis for a roadmap tracking-parent, but it is NEVER a `/issue` target: epics are created
deliberately when structuring the roadmap, not from a captured item. So `/issue` only ever picks from
the six above.)

An escape carries a record the plain kinds do not, and it is not filed without all three lines:

```
Escaped from: <ticket ref>
Found: <what was found>, at <where: the re-test, staging or production, with the link or evidence>
Should have been caught at: <step>
```

`<step>` is exactly ONE of these values, and its label is `caught-at:<value>`: `intake`, `lens-tpm`,
`lens-blind`, `lens-dev`, `lens-exhaust`, `premise-reconcile`, `ready-check`, `eli5`, `build-tests`,
`review-panel`, `staging-test`, `activation-check`, `not-catchable`. With `not-catchable` the line
adds "because <reason>". Why: an escape without its step is just a bug, the step is the thing a
monthly count needs, and a free-text step splits one leak across several spellings so the count
stops adding up. If the step is unclear, ask via AskUserQuestion with the two or three plausible
values as options, exactly as for an unclear label; a guessed step points the fix at the wrong part
of the flow.

One cross-cutting marker exists OUTSIDE the KIND axis: `client`. When the capture is client-engagement
work (a specific client's asks, notes, or demo prep), ADD `client` alongside the KIND label - it
composes with the KIND, never replaces it. It is the taxonomy's one deliberate exception; still do not
invent any other cross-cutting label. (If the project already runs its own label taxonomy, respect
that instead - a wrong label in someone else's system is worse than this default set.)

If the right label is genuinely unclear, DO NOT guess silently. Ask via AskUserQuestion: "This
reads like an X to me - does that category sound right?" with the 2-3 plausible labels as options.
The user's taxonomy is theirs; a wrong silent label is worse than a short question.

## Step 3: Scour open issues for relations (the point of the skill)

GitHub search is keyword-only (no semantic search), and a local skill should NOT stand up an
embedding pipeline. So: pull a BOUNDED candidate set by keyword, then judge relations IN-CONTEXT
with your own reading.

```bash
# 3-6 salient keywords/nouns from the content, OR'd; open issues only; enough fields to judge.
gh issue list --repo "$REPO" --state open --search "<kw1> OR <kw2> OR <kw3>" \
  --json number,title,labels,body --limit 30
```

Read the candidates and decide the relation as ONE of these (a discriminated union - a single
clear verdict, never prose that hedges):

- **duplicate** of `gh#N` - the same item already exists.
- **related** to `gh#N` (one or more) - overlapping or intertwined, but distinct.
- **sub-issue** of `gh#N` - this is a concrete piece of a larger existing item.
- **new** - nothing meaningfully connected.

Be conservative: only call duplicate/related/sub when a human would agree at a glance. Judge on
meaning, not shared words.

## Step 4: Present the verdict concisely, then confirm

If the verdict is `new`, say so in one line and go to Step 5.

Otherwise show it TIGHT: the proposed label, and each related issue as `gh#N - <short title>`
with a half-line on why. Then propose the action and confirm via AskUserQuestion (skip the
confirm only if the user passed `-y`):

- duplicate -> "Looks like a duplicate of gh#N. Amend gh#N with this instead of filing a new one?"
  (recommended) / File new anyway / Cancel.
- related -> "File new and cross-link it to gh#N (and gh#M)?" (recommended) / File new, no link / Cancel.
- sub-issue -> "File new as a sub-issue of gh#N?" (recommended) / File new, standalone / Cancel.

Filing an issue is outward and sticky, so this confirm doubles as the post gate.

## Step 5: File and link

Title: one concise, specific line (no prefix/tag - the label categorizes it). Body: the content
AS-IS + a metadata footer:

```bash
BODY=$(mktemp "${TMPDIR:-/tmp}/issue-XXXXXX.md")
# write the raw content to $BODY unchanged, then:
{ echo; echo "---"; printf '_Captured %s from branch `%s` at commit `%s`._\n' \
    "$(date -u +%Y-%m-%dT%H:%MZ)" "$(git branch --show-current 2>/dev/null || echo '?')" \
    "$(git rev-parse --short HEAD 2>/dev/null || echo '?')"; } >> "$BODY"
gh label create "<label>" --repo "$REPO" 2>/dev/null || true   # idempotent
```

For an `escape`, put its three-line record at the top of the body, above the content, and add a
second label `caught-at:<value>` beside `escape` (for example `caught-at:ready-check`), created the
same idempotent way. The `Escaped from:` ticket counts as a `related` link. If the tracker read in
Step 0 is not GitHub, file the escape there instead, with the same record and labels, through that
tracker's own tool. Why: an escape belongs
beside the ticket it escaped from, or nobody reading that ticket learns it leaked.

Then, per the confirmed verdict:
- **duplicate (user chose amend)**: do NOT create a new issue. Go to Amend on `gh#N` with this content.
- **related**: add a `Relates to: #N` line to the body (bare `#N` so GitHub auto-links it in-repo),
  then `gh issue create --repo "$REPO" --label "<label>" --title "<title>" --body-file "$BODY"`.
  Optionally drop a one-line `Relates to: #<new>` comment on each related issue so the link is
  bidirectional.
- **sub-issue**: `gh issue create ... --parent <N>` if the installed gh supports it (GA June 2026),
  else create then link via `mcp__github__sub_issue_write` if present, else fall back to `related`.
- **new**: `gh issue create --repo "$REPO" --label "<label>" --title "<title>" --body-file "$BODY"`.

## Step 6: Reply with the handle + meta

`gh issue create` prints the URL. Report it plainly and completely:

> Filed `gh#N` (`<label>`): <URL>  -  related to gh#12, gh#7.

That `gh#N` is the referenceable handle. Remove the temp file. Do NOT write to
any ledger - the issue is the record.

## Amend an existing issue

`/issue amend <ref> [text | @file]` adds a follow-up or correction. Resolve `<ref>` (`gh#12`,
`#12`, `12`) to a number `N` in `$REPO`, confirm it exists, append a COMMENT (preserves the
original + the trail; never overwrites the body unless the user asks), preview + confirm unless
`-y`:

```bash
gh issue comment "$N" --repo "$REPO" --body-file "$BODY"
```

Report: "Amended `gh#N` (comment added): <URL>".

## Count escapes

`/issue escapes` shows which step leaks: escapes created in the last 30 days, grouped by their
`caught-at:` label, most first. Run it monthly; a step that tops the list twice running is where
the flow needs a new check.

```bash
SINCE=$(date -u -v-30d +%Y-%m-%d 2>/dev/null || date -u -d '30 days ago' +%Y-%m-%d)
gh issue list --repo "$REPO" --label escape --state all --search "created:>=$SINCE" \
  --limit 500 --json labels --jq '
  map([.labels[].name | select(startswith("caught-at:"))][0] // "caught-at:(missing)")
  | group_by(.) | map({step: .[0], escapes: length}) | sort_by(-.escapes)'
```

A `caught-at:(missing)` row is an escape filed without its step: fix the record, do not drop it. On
another tracker, read `tracker.kind` and the project key from `.claude/pickup.json` and run the same
query in that tracker's own search (label `escape`, created in the last 30 days, grouped by the
`caught-at:` label or field); do not assume which tracker it is.

## The `gh#N` handle

Reference every filed issue as `gh#N` (short, and unmistakably a GitHub issue rather than a Claude
Code session task number, which also looks like `#N`). Inside a GitHub issue/PR body use bare `#N`
so GitHub auto-links it in-repo; use `gh#N` everywhere else (chat, prose, CLAUDE.md).

## Notes

- Files text AS-IS; the skill authors only the title, the label, and the links (plus an escape's record).
- Relations use GitHub's native types: `duplicate_of` (via the MCP or a re-file-as-amend),
  parent/sub-issue, and `Relates to: #N` for the soft "intertwined" case GitHub has no formal
  link for. Do not hand-roll a bespoke relationship store.
- `-y` / `--post` skips the confirm. A different repo can be targeted with `owner/repo`.
- One narrow judgment at a time (classify, then relate) beats one mega-prompt - it is more reliable.
