# Field notes: one release built with the workflow

Lessons from one real build with this plugin: a chat assistant for a marketplace website, Release
1, about 80 tickets and ~790 commits. Figures are approximate (counted by grep). Where a lesson is
now built into the plugin, the line says so.

## 1. What worked, keep it

- **Spec-sharpen before build.** The lens fates caught wrong premises before a line was written: a
  ticket listed as a dependency that was not one, an upstream piece assumed to provide data it did
  not. The cheapest bugs of the release.
- **A reviewer who did not write the code.** Round-1 adversary and security reviews found real P1s
  that the builder and the tests missed: an unavailable tool still passing a safety case, a paid
  replay that could abort midway, a billing race.
- **Fix by class, not by finding.** A re-verify that checked the whole class of a finding caught a
  fix that covered only the sample.
- **A fresh QA agent that uses the app like a visitor.** Found defects every reviewer missed on about
  five tickets, for example a confirmation card that still sent after requests were switched off.
- **The taste gate (springclean).** Stopped a fix loop that kept adding homemade machinery; the
  fourth round netted about -100 lines.
- **A per-ticket list of what only staging can show**, rolled into one release checklist. An honest
  handoff instead of an implied "all tested".
- **Coordinator owns the result, agents execute, claims need pasted proof.** Every time this was
  skipped, something false reached the human or the client.
- **Hooks for the dangerous things** (destructive git, secret-file reads, lock files, migrations).
  Cheap, and never argued with.

## 2. Lessons that apply to any team

1. **Green is a claim, not a fact.** Mocked green is not a live pass; a fetch of the raw HTML said a
   client-side widget was missing when it was there; hand-typed timestamps were 3-5 hours off. Every
   "done", "fixed" or "live" cites the output, the commit or the `file:line`.
2. **Tests can pass with the feature deleted.** Vacuous asserts and meta-tests showed up repeatedly.
   A separate test writer plus "can this test fail on main?" is the fix. The release also
   over-tested: at one point 6,817 test lines for 3,663 code lines.
3. **Review loops spiral when findings have no fate.** Each round's fix adds machinery the next round
   attacks. What stops it: a threat model up front, a fate (FIXED / DEFERRED / DISMISSED with a
   reason) on every finding before the next round, and "back to main plus the minimal delta" when a
   fix opens a new class of defect.
4. **The brief's file allowlist is usually too narrow.** New modules also need the import-linter
   layer, the dead-code whitelist, the test-length cap. Agents contorted code instead of saying so.
5. **Process must be sized to the change.** Small tickets did fine with one reviewer; three reviewers
   on mid-size work produced mostly P3s and nits, and a second model often returned "no findings" on
   small diffs.
6. **The human should get decisions, not questions.** Technical choices are the coordinator's; only
   business questions go up, batched, each with a recommended answer. But a discussion is never a go
   to edit.
7. **Parallel agents leave contradictions.** After any multi-agent rollout, grep the whole set of
   files for the old wording.
8. **Environment traps eat whole sessions.** Worktrees need the env file linked, distinct ports and
   their own test database; a CLI reviewer hung for 15 hours waiting on stdin (`< /dev/null` fixes
   it); a broad `pkill` killed every app on the machine.
9. **Some failures no code gate can catch.** On go-live day the chat was down because of a deploy
   variable and an expired key link. Plan one real request on the target environment as its own step.
10. **Short answers to the human.** Long, dense replies drew explicit negative feedback. Detail goes
    in a file, not in chat.

## 3. Improvements, in order of value

1. **One source of truth per rule.** Review depth was stated in three places, and a memory
   overrode a skill. A rule lives in the skill or in `pickup.json`, never only in memory.
2. **One review-sizing table, enforced by the flow, not remembered.** Small changes get one fresh
   reviewer then QA; security, guards, spend or large changes get the full panel; at most two
   rounds; a finding without a fate blocks the next round. *Now in the plugin: `pickup` reads
   `review.full_panel_when` from `pickup.json` and applies the fate rule.*
3. **One design framing by default, three on demand.** The release produced 32 framing files, none
   cited outside its own design. *Now in the plugin: `tech-design` writes one framing by default and
   three only when a reviewer says the choice is not obvious.*
4. **A lighter paper trail.** One folder per ticket instead of hundreds of flat files; raw reviewer
   output to a scratch folder, not docs; the ticket comment links the review file instead of
   repeating it. The status file became a 507-line append log. *Now in the plugin: `coordinate`
   keeps only the current state and deletes superseded rows; git keeps the history.*
5. **A replay budget per ticket.** One ticket ran five paid replays before anyone ruled "no more".
   *Now in the plugin: `budget.paid_runs_per_ticket` in `pickup.json`; the run stops and reports
   to the coordinator before a paid run that would go over the cap.*
6. **Builder pre-flight.** Before writing code, the builder lists the files it expects to touch
   beyond the allowlist (linter layers, whitelists, fixtures) and stops if any are missing. Cheaper
   than a contorted diff. *Now in the plugin: `build`.*
7. **Agent memory stays about the role, not the ticket.** Most reviewer memories were per-ticket "do
   not re-report" notes; those belong on the ticket. Consolidate memory monthly.
8. **A second-model reviewer as a tool, not a ritual.** Keep it on security, guards, spend and large
   diffs; drop it on small diffs where it mostly says "no findings". Bake the `< /dev/null` and a
   small batch of files per call into the skill.
9. **Seed the safety net on day one.** *Now in the plugin: `project-setup` seeds the safety hooks
   and the environment traps (env link, ports, test database, stdin) in `TRAPS.md`.*
