---
name: issue
description: >
  File a captured idea, escalation, bug, task, or design thought as a GitHub issue in the
  current repo, auto-classified with a label and cross-linked to any related open issues,
  so a loose thought becomes a tracked, referenceable `gh#N`. Use whenever the user wants to
  capture / file / open / track an issue for something, retain an idea, turn an escalation or
  brainfart into a tracked item, or amend an existing one. On filing it classifies the item
  (idea / escalation / bug / task / architecture) and ASKS if the category is unclear, scours open
  issues for duplicates and relations and proposes a merge or link BEFORE creating, then
  replies with the `gh#N` handle, its URL, and the label. Triggers on "/issue", "file this",
  "open an issue for this", "capture this", "track this idea", "log this escalation", "amend
  gh#N by ...". NOT for reviewing code or for filing to an external bug tracker.
allowed-tools: Bash, Read, Write, AskUserQuestion
---

# /issue - capture something as a tracked, related GitHub issue

Turn a loose idea / escalation / bug / task into a GitHub issue with a `gh#N` handle, so it
stops living only in a chat and joins the tracked web of work. Two jobs the raw `gh issue
create` does not do, and the reason this skill exists: (1) it CLASSIFIES the item, and (2) it
finds how the item RELATES to what is already filed and links it, so the web builds itself
instead of every capture landing as an orphan. The text is filed AS-IS; the skill authors only
the title, the label, and the links.

## Step 0: Preflight

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

## Mode: new (default) or amend

`/issue amend <ref> ...` (or "amend / add to / correct gh#N") adds to an existing issue: see
"Amend" below. Otherwise file a NEW issue (Steps 1 to 5).

## Step 1: Get the content

In order: a file if the argument is a path or `@path`; the text following `/issue`; the
conversation content the user clearly means ("file that"); else ask "what should I capture?".
Hold the raw content UNCHANGED - it is the body's core. Do not summarize or reflow it.

## Step 2: Classify (with a bounce-back if unsure)

HARD RULE first: **NEVER file an item that is already done / solved / resolved.** Git history
is its record; a closed issue for finished work is noise. If asked to file something
already handled, say so and skip.

Pick ONE label from the FIXED set (deliberately small - do NOT invent new labels, and NO cross-cutting
or area/subsystem labels): `idea` (a suggestion / design thought / feature wish), `escalation` (a
user-filed "this behaved wrong"), `bug` (a concrete defect), `task` (a discrete unit of work),
`architecture` (an open architecture decision to settle). These overlap on purpose (an escalation is
very often really an idea) - pick the dominant intent. (A 6th label, `epic`, exists on the same KIND
axis for a roadmap tracking-parent, but it is NEVER a `/issue` target: epics are created deliberately
when structuring the roadmap, not from a captured item. So `/issue` only ever picks from the five above.)

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

## The `gh#N` handle

Reference every filed issue as `gh#N` (short, and unmistakably a GitHub issue rather than a Claude
Code session task number, which also looks like `#N`). Inside a GitHub issue/PR body use bare `#N`
so GitHub auto-links it in-repo; use `gh#N` everywhere else (chat, prose, CLAUDE.md).

## Notes

- Files text AS-IS; the skill authors only the title, the label, and the links.
- Relations use GitHub's native types: `duplicate_of` (via the MCP or a re-file-as-amend),
  parent/sub-issue, and `Relates to: #N` for the soft "intertwined" case GitHub has no formal
  link for. Do not hand-roll a bespoke relationship store.
- `-y` / `--post` skips the confirm. A different repo can be targeted with `owner/repo`.
- One narrow judgment at a time (classify, then relate) beats one mega-prompt - it is more reliable.
