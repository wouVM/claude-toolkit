---
name: coordinate
description: >
  Make one chat the coordinator when several chats or sessions work on related tickets at once
  (a release, a feature split over tickets, a fix that lands in another chat's branch): it owns the
  outcome, keeps a session-state file that survives compaction, messages the owner chats before it
  touches their worktrees and after, verifies their "all green" instead of relaying it, tests the
  unmerged combination on staging with a note per ticket of what staging cannot prove, and hands
  the human only the steps that are theirs (merges, tags, production approvals and writes, messages
  to people). Use when the user says "/coordinate", "you are the coordinator", "own the release",
  "track the other chats", "keep the session state", "which PRs are ready", "test the release on
  staging", "what do I still have to do", or when more than one live chat is working towards the
  same ship date. Not needed for a single ticket in a single chat.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, AskUserQuestion, Skill
---

# /coordinate - one chat owns the outcome, the others build

ELI16 first: when four chats each build one ticket for the same release, every one of them can be
right and the release can still be wrong. Each reports its own "green", the human becomes the
message bus between them, and the thing that breaks is the combination nobody ran. So one chat is
told it OWNS the outcome: it tracks every ticket, branch and worktree, checks the other chats' claims
itself, tests the combination before anything merges, and at the end hands the human a short list
of what only a human can do. The other chats build. The human signs, merges and talks to people.

## When this fires

More than one live chat or session is working on tickets that ship together, or one chat's fix has
to land in another chat's branch. For a single ticket in a single chat, `workflow:pickup` and
`workflow:build` already carry the trail and this skill adds nothing.

## The role split

| Role | Owns | Never does |
|---|---|---|
| **Coordinator** (one chat) | The outcome: the ticket and PR table, the session-state file, the combined staging test, the tracker kept current, the human's step list | Build inside an owner's worktree unannounced; relay a claim it has not checked |
| **Owner chat** (one per ticket) | Its ticket end to end through the ticket chain (`workflow:pickup`, `workflow:build`): the branch, the worktree, verify, the review loop, the PR | Touch another ticket's worktree; report "done" without the evidence |
| **Human** | The signature on each ticket, merges, release tags, production approvals and writes, messages to people | Act as the message bus between chats |

The coordinator is still bound by the role fence: it directs and checks, and a build it needs goes
through `/build` or back to the owning chat.

## The session-state file, written before compaction

A long coordinating chat WILL compact, and a coordinator that re-derives its state from memory
reopens decisions that were already settled. So the state lives in a file, written at every
milestone and always before compaction, where the project keeps working notes (for example
`docs/session-state-<date>-<topic>.md`). It holds, in this order:

1. **Role.** "This chat coordinates <release or goal>; the owner chats are ..." One paragraph, so a
   fresh chat that reads only this file knows what it is.
2. **The table.** One row per ticket: ticket, owner chat, branch, worktree path, PR link, head
   commit, state. Take each head from `git rev-parse`, never from memory: a stale head is how an
   unreviewed commit ships.
3. **Next steps, in order.** Numbered, each with who does it.
4. **Decisions not to re-litigate.** Each with its one-line reason, so a later reader (or the next
   compaction) sees that it was decided and why.
5. **Open items.** Each with an owner and what unblocks it.
6. **Access notes.** Which credentials and tools work from here, which do not and the workaround,
   what is read-only.

The test for the file: a fresh chat given only this file can take over without asking a question.

## Talking to owner chats

- **Before touching an owner's worktree or branch** (a fix, a rebase, merging it into a combination
  branch), message the owner to hold off and wait for the acknowledgement. Two chats writing one
  worktree lose work silently, and neither notices until a review sees the wrong diff.
- **When done**, tell the owner what changed and the new head, so its next commit starts from it.
- Each message is self-contained: what, why, which head, and what the owner should do now. Use
  whatever channel the harness offers (a message to a named agent, or a paste the human relays).

## Verify, never relay

An owner chat's "all green" is a claim, not evidence. Before the coordinator repeats it to the
human, the tracker or anyone outside:

- the head in the claim matches the PR's head;
- the verify output was read as pasted, not summarised, and its negatives checked (a subagent that
  says "all green" while a suite is red is a known failure mode);
- the diff actually does what the ticket's acceptance criteria say, checked against the code and not
  against the ticket title.

Every status statement the coordinator makes ("live", "fixed", "covered by X") names its proof: the
commit, the `file:line`, the query and its result. Why: a claim that a safeguard covered a defect
went out on the safeguard's title; it guarded a different case, and the requester found the defect
still there.

## Test the combination on staging, before anything merges

Green PRs one by one do not make a green release. The standard move:

1. Build a throwaway combination branch: the base branch plus every PR in the release, merged
   locally. It is never pushed onto the base and never becomes a PR.
2. Deploy it to staging with the project's deploy-any-branch pipeline, then run the behavioural
   checks against it. Each defect goes back to the chat that owns the ticket, with the evidence.
3. Delete the combination branch once the real PRs merge.

If the project has no pipeline that deploys an arbitrary branch to staging, the first release that
needs one is the moment to add it as a standard pipeline on the base branch, filed as a ticket, not a
one-off built again each time.

**Per ticket, write down what staging cannot prove**, in the ticket and in the state file: staging
talks to a vendor's sandbox, an integration has no staging credentials, a real inbound channel does
not exist there. Each line names the production check that replaces it, so that check is planned
rather than discovered after the release.

## Hand the human only their steps

The coordinator's last deliverable is a short, ordered list of the acts that are the human's alone,
and nothing else on it:

- **Merges**: which PR, in what order, and why that order (for example a code change before the
  config change that relies on it).
- **Tags and releases.**
- **Production approvals and writes**: the exact command, row or setting, and why the coordinator
  cannot do it from here.
- **Messages to people**: drafted, ready to send.

Everything an agent could do is done, not handed over; everything that is the human's is offered,
not done. A step list that makes the human re-derive state, or chase a chat for a status, is the
coordinator's defect.

## After the release: done means switched on

A shipped ticket is done when its activation is observed in production: the config row exists, the
credential is set, the external side is connected, one real event went through. The coordinator
checks this per ticket (read-only) and keeps the ticket open until it holds. Why: a receiver
shipped and was never connected on the vendor side, and it failed quietly for weeks while the
tracker said Done.
