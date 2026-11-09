#!/usr/bin/env bash
# PreToolUse hook (matcher: Edit|Write): a lock file changes only through its package manager, never
# by hand. A hand-edited lock file installs something no manifest asked for, and the next install either
# reverts it or fails on a checksum. Covers the common stacks: npm, yarn, pnpm, bun, poetry, pipenv, uv,
# pip-compile, cargo, bundler, go modules and composer. Change the manifest and run the tool instead.
#
# A requirements .txt with a sibling .in is pip-compile output and is blocked too; a hand-maintained
# requirements.txt with no .in stays editable.
#
# Fails open: no jq, or an unreadable payload, allows with a note on stderr.
set -uo pipefail

ALLOW() { exit 0; }
PAYLOAD=$(cat 2>/dev/null) || ALLOW
[ -n "$PAYLOAD" ] || ALLOW
if ! command -v jq >/dev/null 2>&1; then
  echo "block-lock-files: jq not found, check skipped (install jq to enable it)" >&2
  ALLOW
fi

deny() {
  jq -cn --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

FILE=$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null) || ALLOW
[ -n "$FILE" ] || ALLOW

case "$(basename "$FILE")" in
  package-lock.json|npm-shrinkwrap.json|yarn.lock|pnpm-lock.yaml|bun.lock|bun.lockb|\
  poetry.lock|Pipfile.lock|uv.lock|requirements*.lock|\
  Cargo.lock|Gemfile.lock|go.sum|composer.lock)
    deny "$(basename "$FILE") is a lock file: it changes only through its package manager. Edit the manifest and run the install or lock command instead."
    ;;
  *.txt)
    if [ -f "${FILE%.txt}.in" ]; then
      deny "This requirements file is compiled from $(basename "${FILE%.txt}.in"). Edit the .in file and recompile."
    fi
    ;;
esac

exit 0
