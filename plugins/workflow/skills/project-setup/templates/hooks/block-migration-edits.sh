#!/usr/bin/env bash
# PreToolUse hook (matcher: Edit|Write): a migration that is already on the base branch is never edited.
# It may have run on another machine or in production, so changing it forks the schema history: the
# edited version never runs where the old one already did. A change to the schema is a NEW migration,
# made with the framework's own command.
#
# Covers the common stacks:
#   Django                  */migrations/0001_*.py
#   Alembic / Flask-Migrate */alembic/versions/*.py, */migrations/versions/*.py
#   Rails                   */db/migrate/*.rb
#   Prisma                  */prisma/migrations/*/migration.sql
#
# Only a migration that exists on the base branch is frozen. The base is the first of origin/HEAD,
# origin/main, main, origin/master, master that resolves. A migration that is untracked, only staged, or
# committed only on a feature branch is allowed: it has not reached the base, so it has run nowhere that
# matters yet (a Rails or Alembic stub has to be filled in, a branch's own migration can be reworked).
#
# Fails open: no jq, no git, no resolvable base, or an unreadable payload, allows (with a note on stderr
# for jq).
set -uo pipefail

ALLOW() { exit 0; }
PAYLOAD=$(cat 2>/dev/null) || ALLOW
[ -n "$PAYLOAD" ] || ALLOW
if ! command -v jq >/dev/null 2>&1; then
  echo "block-migration-edits: jq not found, check skipped (install jq to enable it)" >&2
  ALLOW
fi

FILE=$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null) || ALLOW
[ -n "$FILE" ] || ALLOW

# The leading slash lets one `*/` pattern match a relative path as well as an absolute one.
case "/$FILE" in
  */migrations/[0-9]*.py|*/alembic/versions/*.py|*/migrations/versions/*.py|\
  */db/migrate/*.rb|*/prisma/migrations/*/migration.sql) ;;
  *) ALLOW ;;
esac

DIR=$(dirname "$FILE")
[ -d "$DIR" ] || ALLOW
PREFIX=$(git -C "$DIR" rev-parse --show-prefix 2>/dev/null) || ALLOW
BASE=""
for REF in origin/HEAD origin/main main origin/master master; do
  if git -C "$DIR" rev-parse --verify --quiet "$REF^{commit}" >/dev/null 2>&1; then BASE=$REF; break; fi
done
[ -n "$BASE" ] || ALLOW
git -C "$DIR" cat-file -e "$BASE:$PREFIX$(basename "$FILE")" 2>/dev/null || ALLOW

jq -cn '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:"This migration is already on the base branch and is never edited: it may have run elsewhere. Change the model or schema and generate a NEW migration with the framework command (makemigrations, alembic revision --autogenerate, rails generate migration, prisma migrate dev)."}}'
exit 0
