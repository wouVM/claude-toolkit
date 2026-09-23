#!/usr/bin/env bash
# TOOLS CHECK: before blaming a credential, find out what is actually wrong with it.
#
# WHY THIS EXISTS. A 401 reads like "the token expired", and the reflex is to rotate it. Often the token is
# fine and the VALUE is broken: two lines of a shell profile joined into one, so the variable ends in the
# word "export"; a stray quote or trailing space; a variable set in a profile this shell never reads. This
# script separates those cases and says which one it is, in one plain line per check.
#
# WHAT IT DOES, per configured integration, in order, stopping at the first failure:
#   1. the variable is present in THIS environment              -> MISSING
#   2. the value's shape is sane (no whitespace, no quotes, not -> BAD SHAPE
#      ending in "export", the expected prefix and length when known)
#   3. one authenticated READ-ONLY call                         -> OK / 401 / 403 / FAIL
#
# IT IS READ-ONLY AND NEVER PRINTS A SECRET. It reads environment variables, prints variable NAMES and
# verdicts, and makes GET calls only. Credentials go to curl on stdin (--config -), never on the command
# line, so they do not show up in the process list either.
#
# CONFIGURE (project-setup fills these in; delete the integrations this project does not use):
#   CHECKS                       - which integrations to check, space separated
#   the *_VAR names              - the environment variable NAMES this project uses for each
#   the *_PREFIX / *_MIN_LEN     - leave empty unless you know the vendor's current token format
#
# Run it as `bash tools-check.sh`, never `source` it: it uses bash indirection, and a login shell in zsh
# would parse it differently. It sees exactly what a child process sees, which is the point: a variable
# that is set but not exported is MISSING here and missing for every tool too.
# Exit code: 0 when every check is OK, 1 otherwise.
set -u

CHECKS="${TOOLS_CHECK:-github bitbucket jira}"

# GitHub: gh keeps its own login; GH_TOKEN / GITHUB_TOKEN override it when set, so their shape is checked too.
GITHUB_TOKEN_VARS='GH_TOKEN GITHUB_TOKEN'
GITHUB_PREFIX=''            # e.g. a fine-grained token prefix, if the team uses only one kind
GITHUB_MIN_LEN=''

# Bitbucket: basic auth with a user (or account e-mail) and an API token / app password.
BITBUCKET_USER_VAR='BITBUCKET_USER'
BITBUCKET_TOKEN_VAR='BITBUCKET_TOKEN'
BITBUCKET_PREFIX=''
BITBUCKET_MIN_LEN=''

# Jira Cloud: basic auth with the account e-mail and an API token, against $JIRA_SITE
# (either "yoursite.atlassian.net" or a full https:// URL).
JIRA_SITE_VAR='JIRA_SITE'
JIRA_EMAIL_VAR='JIRA_EMAIL'
JIRA_TOKEN_VAR='JIRA_API_TOKEN'
JIRA_PREFIX=''
JIRA_MIN_LEN=''

FAILED=0

say() {
  # say <STATUS> <integration> <message>
  printf '%-10s %-10s %s\n' "$1" "$2" "$3"
  if [ "$1" != "OK" ]; then FAILED=1; fi
}

# need_var <integration> <VAR_NAME>: prints MISSING and returns 1 when the variable is empty or unset.
need_var() {
  local name="$2"
  if [ -z "${!name:-}" ]; then
    say "MISSING" "$1" "\$$name is not set in this environment (set in a profile this shell does not read, or not exported?)"
    return 1
  fi
  return 0
}

# check_shape <integration> <VAR_NAME> [prefix] [min_len]: returns 1 (after saying why) on a bad shape.
# It never prints the value; at most its length.
check_shape() {
  local integ="$1" name="$2" prefix="${3:-}" min_len="${4:-}"
  local value="${!name:-}"
  case "$value" in
    *[[:space:]]*)
      say "BAD SHAPE" "$integ" "\$$name contains whitespace (a trailing space or newline, or two lines joined)"
      return 1 ;;
    *export)
      say "BAD SHAPE" "$integ" "\$$name ends in the word 'export' (two shell profile lines joined into one?)"
      return 1 ;;
    *\"*|*\'*|*\\*)
      say "BAD SHAPE" "$integ" "\$$name contains a quote or backslash (quoting copied into the value?)"
      return 1 ;;
  esac
  if [ -n "$prefix" ]; then
    case "$value" in
      "$prefix"*) ;;
      *)
        say "BAD SHAPE" "$integ" "\$$name does not start with the expected prefix '$prefix'"
        return 1 ;;
    esac
  fi
  if [ -n "$min_len" ] && [ "${#value}" -lt "$min_len" ]; then
    say "BAD SHAPE" "$integ" "\$$name is ${#value} characters, expected at least $min_len (truncated?)"
    return 1
  fi
  return 0
}

# http_status <user_var> <token_var> <url>: prints the HTTP status of an authenticated GET, "000" on no answer.
# The credentials reach curl on stdin, so they never appear in argv. check_shape has already ruled out
# quotes and backslashes, which is what keeps the config line below well-formed.
http_status() {
  local user="${!1:-}" token="${!2:-}" url="$3"
  printf 'user = "%s:%s"\n' "$user" "$token" \
    | curl --silent --show-error --output /dev/null --write-out '%{http_code}' \
        --max-time 15 --config - --header 'Accept: application/json' "$url" 2>/dev/null \
    || true
}

report_http() {
  # report_http <integration> <status> <what was called>
  case "$2" in
    200) say "OK" "$1" "authenticated read works ($3)" ;;
    401) say "401" "$1" "credential rejected: wrong, expired or revoked token, or the wrong user/e-mail for it ($3)" ;;
    403) say "403" "$1" "credential accepted but lacks the scope or permission for this read ($3)" ;;
    000|"") say "FAIL" "$1" "no answer: network, DNS, proxy or a wrong host ($3)" ;;
    *)   say "FAIL" "$1" "unexpected HTTP $2 ($3)" ;;
  esac
}

check_github() {
  local var
  for var in $GITHUB_TOKEN_VARS; do
    if [ -n "${!var:-}" ]; then
      check_shape github "$var" "$GITHUB_PREFIX" "$GITHUB_MIN_LEN" || return
    fi
  done
  if ! command -v gh >/dev/null 2>&1; then
    say "MISSING" github "the gh CLI is not installed"
    return
  fi
  if gh auth status >/dev/null 2>&1; then
    say "OK" github "gh auth status: logged in"
  else
    say "401" github "gh auth status: not logged in, or the token it holds is rejected (run gh auth status to see which host)"
  fi
}

check_bitbucket() {
  need_var bitbucket "$BITBUCKET_USER_VAR" || return
  need_var bitbucket "$BITBUCKET_TOKEN_VAR" || return
  check_shape bitbucket "$BITBUCKET_USER_VAR" || return
  check_shape bitbucket "$BITBUCKET_TOKEN_VAR" "$BITBUCKET_PREFIX" "$BITBUCKET_MIN_LEN" || return
  local url='https://api.bitbucket.org/2.0/user'
  report_http bitbucket "$(http_status "$BITBUCKET_USER_VAR" "$BITBUCKET_TOKEN_VAR" "$url")" "GET $url"
}

check_jira() {
  need_var jira "$JIRA_SITE_VAR" || return
  need_var jira "$JIRA_EMAIL_VAR" || return
  need_var jira "$JIRA_TOKEN_VAR" || return
  check_shape jira "$JIRA_SITE_VAR" || return
  check_shape jira "$JIRA_EMAIL_VAR" || return
  check_shape jira "$JIRA_TOKEN_VAR" "$JIRA_PREFIX" "$JIRA_MIN_LEN" || return
  local site="${!JIRA_SITE_VAR}"
  site="${site%/}"
  case "$site" in
    http://*|https://*) ;;
    *) site="https://$site" ;;
  esac
  local url="$site/rest/api/3/myself"
  report_http jira "$(http_status "$JIRA_EMAIL_VAR" "$JIRA_TOKEN_VAR" "$url")" "GET $url"
}

if ! command -v curl >/dev/null 2>&1; then
  say "MISSING" curl "curl is not installed; the HTTP checks cannot run"
fi

for integration in $CHECKS; do
  case "$integration" in
    github)    check_github ;;
    bitbucket) check_bitbucket ;;
    jira)      check_jira ;;
    *)         say "FAIL" "$integration" "no check defined for this integration in tools-check.sh" ;;
  esac
done

exit "$FAILED"
