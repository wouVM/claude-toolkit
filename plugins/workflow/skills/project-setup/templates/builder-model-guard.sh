#!/usr/bin/env bash
# THE ROLE FENCE: the coordinating model DIRECTS and CHECKS, the building model EXECUTES.
#
# WHY THIS IS A HOOK AND NOT A SENTENCE. The rule can live in CLAUDE.md and still not bind: a session can
# read it, quote it back, and build anyway. The failure is not ignorance. A design session ("think about
# this") becomes a build ("go ahead") with no boundary event, and prose does not fire at a boundary. The
# reader is the model, at the moment it is least able to notice.
#
# WHAT IT FENCES, and why the cut is at EDIT rather than READ. A read is ambiguous - reviewing a diff is
# the coordinator's actual job, and blocking reads would break the check half of "directs and checks". An
# EDIT to build code is not ambiguous: it is the role boundary already crossed.
#
# WHAT IT DELIBERATELY DOES NOT FENCE:
#   - a SUBAGENT's edits, whatever model it runs. Delegation is the behaviour this exists to produce, so it
#     is never the thing refused. The discriminator is structural, not a guess: a subagent's PreToolUse
#     payload carries `agent_id` and a main-session call does not. The gap this leaves is honest and small:
#     a coordinator that dispatches a COORDINATOR-model subagent is allowed through, which costs a
#     deliberate `model:` override - a choice rather than a drift.
#   - MARKDOWN anywhere, including under a build directory. A spec, a ledger, a trap-book entry and a
#     skill's prose are coordination work, which is exactly what the coordinator should spend itself on.
#   - every path outside the build directories.
#
# IT FAILS OPEN, ALWAYS. A guard that blocks the build because jq moved or a transcript was rotated is a
# worse failure than the one it prevents: it would strand the session with no way forward and no way to
# tell why. Every unknown resolves to "allow" - the exit at the foot of this file is the only verdict a
# confused run can reach.
#
# CONFIGURE TWO THINGS AND NOTHING ELSE:
#   COORDINATOR_PATTERN - a shell glob matching the model id that must not build (e.g. *fable*, *opus*).
#   BUILD_DIRS          - this project's build directories, one per line, no globs (just the names).
#
# Both are matched literally below rather than expanded as case patterns: a quoted variable in a `case`
# arm does NOT expand its `|` alternations, so a "dir/*|dir/*" string would match nothing and the fence
# would silently never fire. A fence that never fires is worse than no fence, because it is believed.
set -uo pipefail

COORDINATOR_PATTERN='*fable*'
BUILD_DIRS='src
lib
app
packages
server
tests'

ALLOW() { exit 0; }

PAYLOAD=$(cat 2>/dev/null) || ALLOW
[ -n "$PAYLOAD" ] || ALLOW
command -v jq >/dev/null 2>&1 || ALLOW

# 1. A subagent is the delegation we want. Never refuse it.
AGENT_ID=$(printf '%s' "$PAYLOAD" | jq -r '.agent_id // empty' 2>/dev/null) || ALLOW
[ -z "$AGENT_ID" ] || ALLOW

# 2. Which model is driving this session? The payload does not carry it; the transcript records it per
#    assistant message, and the message carrying THIS tool call is already written when the hook fires.
#    Only the tail is read, so the cost does not grow with the session.
TRANSCRIPT=$(printf '%s' "$PAYLOAD" | jq -r '.transcript_path // empty' 2>/dev/null) || ALLOW
[ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ] || ALLOW
MODEL=$(tail -n 400 "$TRANSCRIPT" 2>/dev/null | grep -o '"model":"[^"]*"' | tail -n 1) || ALLOW
# No model found in the tail (a very quiet session, a rotated transcript) is an unknown, so it allows.
[ -n "$MODEL" ] || ALLOW
case "$MODEL" in $COORDINATOR_PATTERN) ;; *) ALLOW ;; esac

# 3. Is the target build code? Resolved against the project root rather than the cwd, which drifts.
FILE=$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || ALLOW
[ -n "$FILE" ] || ALLOW
ROOT=${CLAUDE_PROJECT_DIR:-$(printf '%s' "$PAYLOAD" | jq -r '.cwd // empty' 2>/dev/null)}
[ -n "$ROOT" ] || ALLOW
case "$FILE" in "$ROOT"/*) REL=${FILE#"$ROOT"/} ;; *) ALLOW ;; esac

# Prose is coordination work wherever it lives.
case "$REL" in *.md) ALLOW ;; esac

DIR=${REL%%/*}
# A path with no directory part (a root-level file) is never build code.
[ "$DIR" != "$REL" ] || ALLOW
printf '%s\n' "$BUILD_DIRS" | grep -qxF "$DIR" || ALLOW
cat <<JSON
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Role fence (CLAUDE.md cost discipline): this session is the coordinating model, which DIRECTS and CHECKS. Editing build code in $DIR/ is the builder's job. Write the spec (a .md is always allowed), then dispatch a builder with the Agent tool, naming a file allowlist and a token budget. A subagent's edits are never fenced, whatever it touches. Review its diff here. If this specific edit genuinely belongs to the coordinator, ask the user to make the call rather than working around the fence."}}
JSON
exit 0
