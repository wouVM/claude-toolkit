---
name: worktree
description: >
  Isolate a piece of work in its own git worktree, per ticket and per sub-repo, branched from a
  freshly fetched base, and keep the conflict discipline: detect a conflicting merge with a
  write-nothing dry run and STOP, never resolve it, never rebase, merge, force-push or reset.
  Use when the user says "/worktree", "work on this in isolation", "set up a worktree for
  TICKET-123", "spin up a branch env for this repo", or when several agents or people are about
  to touch the same repo at once. workflow:pickup calls this for every ticket it takes. NOT a
  merge tool and NOT a conflict resolver: it reports conflicts to a human and leaves the
  evidence in place.
allowed-tools: Read, Glob, Grep, Bash
---

# /worktree - one ticket, one isolated checkout, conflicts detected and handed over

ELI16 first: a git repo normally has one working copy, and `git checkout` changes it for everyone and
everything using that folder. A worktree is a second folder attached to the same repo with its own
branch checked out, so two pieces of work can run side by side without touching each other. This
skill creates one per ticket, and it refuses to make the one decision that looks mechanical but is
not: which side of a conflict wins.

## Never work in the primary checkout

A `git checkout` in the repo's main folder is GLOBAL to that repo. If a parallel run, a scheduled
job, or a person is working there, switching the branch yanks the code out from under them mid-edit,
and the damage shows up later somewhere that looks unrelated. So automation never checks out in the
primary folder. It gets its own worktree, always, even when nothing else appears to be running: "I
checked and nobody was using it" is a race, not a check.

## One worktree per ticket, in the SUB-repo

In a meta-repo that contains several independent git repos, the container is not the unit of
isolation. Each sub-repo has its own history, its own base branch, and its own PRs, so the worktree
belongs in the sub-repo the ticket actually touches. A worktree of the container would isolate the
wrong thing: it gives you a second copy of the folder structure while the sub-repo underneath is
still the single shared checkout every run is fighting over. Branch, base and PR all live in the
sub-repo, so the isolation has to live there too.

## Create it

From the sub-repo, fetch the base FIRST so the branch starts from what is on the remote right now,
not from whatever the local ref happened to be last week:

```bash
cd "$REPO_PATH"
git fetch origin "$BASE"
git worktree add -b "$BRANCH" "$WORKTREE_ROOT/$TICKET-$REPO_SHORT" "origin/$BASE"
```

Naming: the directory is `<worktree_root>/<ticket>-<repo-short>`, so several sub-repos for one ticket
sit next to each other and are obvious at a glance. The branch follows the project's own convention
(`branch_format` in `.claude/pickup.json`, e.g. `<type>/<ticket>/<slug>`); the project's git skill
owns that format where it has one.

## Conflicts are DETECTED, never auto-resolved

Before opening a PR, re-fetch the base and dry-run the merge:

```bash
git fetch origin "$BASE"
git merge-tree --write-tree "origin/$BASE" HEAD
```

`--write-tree` computes the merge in the object database and writes NOTHING to the working tree or
to any branch, so this is safe to run at any point and leaves no cleanup. A non-zero exit means a
conflict; the output names the conflicting paths.

On a conflict: STOP. Report the conflicting paths on the ticket, leave the branch pushed, and hand it
to a human.

The reason is not that resolution is hard. It is that two changes can both be correct and still need
a judgment call about which one wins, and that call needs to know what each change was FOR, which is
exactly the context an automated run does not have. Automatic resolution is a correctness decision
wearing mechanical clothes: it looks like textual bookkeeping and it silently picks a behaviour.

## The four commands automation does not run

Never `git rebase`, `git merge`, `git push --force`, or `git reset --hard` in an unattended run. Each
rewrites or discards history that somebody else may already be building on, and each is a silent
success when it goes wrong. If a project's own git skill already forbids these, that refusal stands
and this skill does not widen it: a narrower house rule always wins over this one.

## Cleanup, and when NOT to clean up

Once the PR is open and the branch is pushed, remove the worktree:

```bash
git worktree remove "$WORKTREE_ROOT/$TICKET-$REPO_SHORT"
git worktree prune
```

**Never remove a worktree whose run stopped on a failing verify or a detected conflict.** That
working tree is the evidence: the exact state the run was in when it stopped, reproducible without
re-running anything. Removing it turns a five-minute look into a re-investigation, and the branch
alone does not carry the untracked files, the test artifacts, or the partial state that made the
failure legible.
