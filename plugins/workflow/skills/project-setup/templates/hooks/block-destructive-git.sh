#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash): refuse the two git commands that destroy work nobody can get back.
#   - a bare force push (--force, -f, a combined short flag like -uf, or a +refspec), which overwrites
#     remote commits the pusher has not seen. --force-with-lease is allowed: it refuses exactly that.
#   - git reset --hard, which throws away uncommitted work. git stash or git revert does the same job
#     and keeps it.
# Every segment of a compound command is checked (`cd x && git push -f` is caught), after stripping any
# number of `-C <path>` and `-c key=val` global options, quoted or not. A hook rather than a deny rule:
# deny rules match the command string as typed, and a compound command or a -C slips past them.
# These hooks are a safety net against accidents, not a security boundary.
#
# Fails open: no jq, or an unreadable payload, allows with a note on stderr.
set -uo pipefail

ALLOW() { exit 0; }
PAYLOAD=$(cat 2>/dev/null) || ALLOW
[ -n "$PAYLOAD" ] || ALLOW
if ! command -v jq >/dev/null 2>&1; then
  echo "block-destructive-git: jq not found, check skipped (install jq to enable it)" >&2
  ALLOW
fi

deny() {
  jq -cn --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

CMD=$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.command // empty' 2>/dev/null) || ALLOW
[ -n "$CMD" ] || ALLOW

# One command per line, so each git invocation is judged on its own.
SEGMENTS=$(printf '%s\n' "$CMD" | awk '{gsub(/&&|\|\||;|\|/, "\n"); print}')

# `git -C <path>` or `git -c key=val`, the value bare, 'single' or "double" quoted; the rest kept.
GLOBAL_OPT="^git[[:space:]]+-[cC][[:space:]]+('[^']*'|\"[^\"]*\"|[^[:space:]]+)(.*)$"

while IFS= read -r SEG; do
  SEG=$(printf '%s' "$SEG" | sed -E 's/^[[:space:]]+//')
  while [[ $SEG =~ $GLOBAL_OPT ]]; do SEG="git${BASH_REMATCH[2]}"; done

  if printf '%s' "$SEG" | grep -qE '^git[[:space:]]+push([[:space:]]|$)'; then
    printf '%s' "$SEG" | grep -q -- '--force-with-lease' && continue
    if printf '%s' "$SEG" | grep -qE '(--force|[[:space:]]-[a-zA-Z]*f[a-zA-Z]*)([[:space:]]|$)|[[:space:]]\+[^[:space:]]'; then
      deny "A bare force push is not allowed. Push normally, or use --force-with-lease after a rewrite the human approved."
    fi
  fi

  if printf '%s' "$SEG" | grep -qE '^git[[:space:]]+reset[[:space:]]+(.*[[:space:]])?--hard'; then
    deny "git reset --hard is not allowed: it discards uncommitted work. Use git stash or git revert instead."
  fi
done <<< "$SEGMENTS"

exit 0
