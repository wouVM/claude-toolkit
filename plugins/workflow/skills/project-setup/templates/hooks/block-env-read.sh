#!/usr/bin/env bash
# PreToolUse hook (matcher: Read|Write|Edit|Grep): .env files hold the project's keys and secrets, and
# an agent never reads or writes them. Blocks `.env`, `.env.*` (`.env.test` too), `*.env` and `.envrc`;
# allows the templates ending in `.example`, `.sample`, `.dist` or `.template` (`.env.example`,
# `.env.local.example`), which carry the variable NAMES an agent needs. Checks the file_path, path and
# glob fields, so a Grep aimed at a .env, or with a glob like `*.env*`, is caught too. A Grep with a
# glob that does not name .env at all (`*`, or none) over a directory holding one is not caught.
#
# What it does not cover: a shell command (`cat .env`) goes through Bash, not these tools. Pair it with a
# `Bash(cat .env*)` style deny rule if the project needs that door shut as well.
#
# Fails open: no jq, or an unreadable payload, allows with a note on stderr.
set -uo pipefail

ALLOW() { exit 0; }
PAYLOAD=$(cat 2>/dev/null) || ALLOW
[ -n "$PAYLOAD" ] || ALLOW
if ! command -v jq >/dev/null 2>&1; then
  echo "block-env-read: jq not found, check skipped (install jq to enable it)" >&2
  ALLOW
fi

TARGETS=$(printf '%s' "$PAYLOAD" | jq -r '.tool_input | (.file_path // empty), (.path // empty), (.glob // empty)' 2>/dev/null) || ALLOW

while IFS= read -r TARGET; do
  [ -n "$TARGET" ] || continue
  case "$(basename "$TARGET")" in
    *.example|*.sample|*.dist|*.template) continue ;;
    .env|.env.*|*.env|.envrc|*.env\**)
      jq -cn '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:".env files are restricted: they hold secrets. Read .env.example for the variable names, and ask the human for a value."}}'
      exit 0
      ;;
  esac
done <<< "$TARGETS"

exit 0
