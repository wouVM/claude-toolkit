# Stop hook - the completion check

A `Stop` hook of type `"prompt"`: before the assistant ends its turn, a small model reads the final
message and answers ALLOW or BLOCK. BLOCK sends the assistant back to finish; ALLOW lets it stop.

It exists to catch one failure (claiming done while an asked-for step was skipped) without creating
a worse one (an assistant that cannot stop). The ALLOW list is therefore long and explicit, and
"when in doubt, ALLOW" is part of the text. The waiting rule matters most: an assistant that
launched background work ends its turn to wait for it, and a hook that blocks that forces empty
turns, polling or relaunching, which is the defect, not the cure.

Trim the authorization-boundary line to this project's own boundaries (its external systems, its
production, its hand-offs to people). Keep the rest as written. The text between the markers is
the hook's `prompt` value; `$ARGUMENTS` is where the hook input (the stop reason and the final
message) is substituted.

<!-- BEGIN PROMPT -->
```
Review the assistant's final message before it stops. Decide ALLOW or BLOCK.

ALLOW, without exception, when the message does any of these:
- Answers the question the user actually asked, and any further action would be a NEW task the user has not asked for.
- Stops at an authorization boundary and says so: pushing, merging, opening or filing something in an external system (a PR, a ticket, an e-mail, a message to a person), assigning work to a person, touching production data or config, credentials, deleting files the assistant did not create. These are the user's decisions; offering them is correct, doing them unasked is the defect.
- Reports a named stop from a skill or rule (for example: an unconfigured route, a merge conflict, the review rounds exhausted, never-merge, a reconcile that has to happen first). A designed stop is not laziness.
- Reports a genuine external blocker it cannot resolve itself (credentials that need an interactive login, a server that refuses to connect, a missing permission) and states what it already tried.
- Completes the requested work and then lists optional follow-ups. An offer AFTER finishing is not deferral.
- Is waiting on work it already launched and that is still running (a background agent, workflow or command whose completion notification re-invokes the assistant), and says what it will do with the result. Ending the turn is how the assistant waits; it cannot finish work whose output has not arrived. Polling, sleeping or re-launching instead would be the defect.

BLOCK only when ALL of these hold: the remaining work was explicitly requested, it is inside the assistant's authority (local files, tests, reads, analysis), nothing above applies, and the message still shows one of: claiming done without running the tests it said it would run; 'I would need to' / 'you could' for a step the user asked for; abandoning after a first error without one retry or diagnosis; a TODO or placeholder left where real work was requested; skipping a verification step that was in the agreed plan.

When in doubt, ALLOW. Respond with exactly 'ALLOW' or 'BLOCK: <one sentence naming the explicitly requested, in-authority step that was skipped>'.

Assistant's stop reason and final message:
$ARGUMENTS
```
<!-- END PROMPT -->
