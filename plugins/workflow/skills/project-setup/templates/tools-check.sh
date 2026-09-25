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
# The two OPTIONAL production checks (prod-db, logs) run a command you configure instead of an HTTP call,
# so their verdicts use the same meaning with non-HTTP names:
#   MISSING   the command (psql, gcloud, ...) or a variable it needs is not there
#   BAD SHAPE the connection-URL variable, when one is configured, is malformed
#   REJECTED  the credential was refused (the 401 of a database or a CLI)
#   DENIED    the credential works but lacks the permission for this read (the 403)
#   FAIL      no answer (proxy not running, wrong host) or an error it cannot classify
#   WRITABLE  prod-db only: the role has a write path (a write privilege on a relation or sequence, CREATE
#             on a schema or the database, a SECURITY DEFINER function it may run, a powerful role
#             attribute, membership in any other role, or objects it owns). Stop using it, tell the admin.
#   READ-ONLY-DEFAULT-OFF  prod-db only: no write path found, but default_transaction_read_only is off.
#             A failure: the runbook's pass needs both.
#   SKIP      not configured for this project; not a failure
#
# IT IS READ-ONLY AND NEVER PRINTS A SECRET. It reads environment variables, prints variable NAMES and
# verdicts, and makes GET calls only. Credentials go to curl on stdin (--config -), never on the command
# line, so they do not show up in the process list either. The production checks never print what the
# configured command returns or its error text (either can carry a connection string or personal data):
# only a classified verdict. The prod-db check NEVER WRITES, not even a temporary table or a transaction it
# rolls back: it runs one SELECT over settings and the privilege catalogue (see PRODDB_SQL_TEMPLATE below).
#
# CONFIGURE (project-setup fills these in; delete the integrations this project does not use):
#   CHECKS                       - which integrations to check, space separated
#   the *_VAR names              - the environment variable NAMES this project uses for each
#   the *_PREFIX / *_MIN_LEN     - leave empty unless you know the vendor's current token format
#   PRODDB_CMD / LOGS_CMD        - the read-only commands from CLAUDE.md "Reading production"; empty = SKIP
#
# Run it as `bash tools-check.sh`, never `source` it: it uses bash indirection, and a login shell in zsh
# would parse it differently. It sees exactly what a child process sees, which is the point: a variable
# that is set but not exported is MISSING here and missing for every tool too.
# Exit code: 0 when every check is OK or SKIP, 1 otherwise.
set -u

CHECKS="${TOOLS_CHECK:-github bitbucket jira prod-db logs}"

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

# Production database, READ-ONLY (optional). PRODDB_CMD is the command that runs SQL read from stdin
# against production as the read-only role and prints the result, exactly as CLAUDE.md documents it, e.g.
#   psql "$PROD_RO_DATABASE_URL" -X -A -t      or      psql "service=prod_ro" -X -A -t
# (a Django project: ENV_FILE=<read-only settings file> python manage.py dbshell). It must take SQL on stdin.
# Keep the password out of this line: reference a variable, a service file or ~/.pgpass. Empty = SKIP.
# PRODDB_CMD / LOGS_CMD are trusted project config run by bash; set them in this file (reviewed in git), never
# from untrusted input. Safety comes from the read-only role, which this check verifies.
PRODDB_CMD=''             # set here, reviewed in git; no environment override
PRODDB_URL_VAR=''           # e.g. PROD_RO_DATABASE_URL when PRODDB_CMD reads a URL-form variable; shape-checked
PRODDB_CONNECT_TIMEOUT='10' # seconds, passed as PGCONNECT_TIMEOUT (honoured by psql and every libpq client)

# SECURITY DEFINER functions the role may execute that the admin has reviewed and approved as read-only.
# One entry per exact signature, as the runbook's inventory query prints it (schema.name(identity args)),
# entries separated by ';', e.g. 'public.report_totals(integer); billing.summary(date, date)'. An overload
# with other arguments is a different function and is NOT approved by its sibling. Empty = none approved.
# Only letters, digits and _ . , ( ) [ ] ; and spaces are accepted, never a quote: it goes into the SQL as
# a literal (PRODDB_CMD is any SQL runner, so there is no client-side bind variable to use instead).
PRODDB_ALLOWED_FUNCS=''   # set here, reviewed in git; no environment override

# The one statement prod-db runs: a SELECT over settings and the privilege catalogue, nothing else. Postgres.
# "Non-system" below means every schema except information_schema and the reserved pg_* ones (pg_catalog,
# pg_toast, other sessions' pg_temp_*). It prints one line of key=value pairs; every counter must be 0 and
# every flag false for OK:
#   ro             default_transaction_read_only for this session (the value SHOW prints); must be on
#   db_create      may the role CREATE schemas in this database
#   schema_create  non-system schemas the role may CREATE objects in (before Postgres 15, PUBLIC may in public)
#   direct         INSERT/UPDATE/DELETE/TRUNCATE/TRIGGER/MAINTAIN grants made to the role itself
#                  (information_schema; a plain string compare, safe on every version)
#   relations      tables, partitioned tables, views, materialized views and foreign tables the role holds
#                  INSERT, UPDATE, DELETE, TRUNCATE or TRIGGER on by ANY route: a direct grant, an inherited
#                  role, PUBLIC, ownership or superuser (has_table_privilege over pg_class)
#   maintain       relations the role holds MAINTAIN on (Postgres 17+: VACUUM, ANALYZE, REINDEX, CLUSTER,
#                  REFRESH MATERIALIZED VIEW, LOCK TABLE). Always 0 before 17, where the privilege does not
#                  exist; the CASE keeps older servers from ever evaluating the 'MAINTAIN' string
#   sequences      sequences the role may advance or set (USAGE or UPDATE; SELECT alone only reads them)
#   secdef_funcs   SECURITY DEFINER functions/procedures the role may EXECUTE (they run with their owner's
#                  rights, so any of them can write), minus PRODDB_ALLOWED_FUNCS
#   role_attrs     the role is SUPERUSER, CREATEROLE, CREATEDB or REPLICATION
#   set_role       roles it is a member of, inherited or not (it holds their rights, or can SET ROLE to them).
#                  Counted conservatively: every role except five predefined ones that can only read by
#                  design: pg_read_all_data (SELECT on everything), pg_read_all_settings, pg_read_all_stats,
#                  pg_stat_scan_tables (read-only views and functions) and pg_monitor (only those three
#                  read roles). Every other membership counts, including pg_write_all_data, pg_signal_backend,
#                  the server-file roles and pg_database_owner (which the database owner holds implicitly).
#   owned          non-system objects the role OWNS (relations, functions, schemas, types, large objects):
#                  an owner can ALTER or DROP them whatever the grants say
#   columns        relations with a column-level INSERT or UPDATE grant (has_table_privilege does not see
#                  column grants; has_any_column_privilege does, and also counts table-level ones)
#   other_writes   the remaining ACL kinds that allow a persistent write or DDL, summed (the runbook's step 8
#                  lists them one by one): large objects with an UPDATE grant to the role or PUBLIC (from
#                  lomacl via aclexplode: no has_largeobject_privilege exists up to Postgres 17), plus 1 when
#                  lo_compat_privileges is on (that switches large-object checks off for everyone),
#                  tablespaces with CREATE, foreign-data wrappers with USAGE (CREATE SERVER), foreign servers
#                  with USAGE (CREATE USER MAPPING, foreign tables), and Postgres 15+ parameter grants
#                  (ALTER SYSTEM, or SET on a parameter a plain user cannot set). pg_parameter_acl does not
#                  exist before 15, so that part runs through query_to_xml inside a CASE and is never even
#                  parsed on 14
#
# EVERY ACL kind a GRANT can target in Postgres 14-17, and where it is handled:
#   table/view/matview/foreign table  INSERT UPDATE DELETE TRUNCATE TRIGGER -> relations, direct
#                                     MAINTAIN (17+)                       -> maintain
#                                     REFERENCES: harmless alone (an FK needs a table the role owns or
#                                     may CREATE -> owned, schema_create); SELECT: read
#   column                            INSERT UPDATE -> columns; REFERENCES: as above; SELECT: read
#   sequence                          USAGE UPDATE -> sequences; SELECT: read
#   database                          CREATE -> db_create; TEMPORARY -> db_temp (allowed, see below);
#                                     CONNECT: no write (see the runbook's note on other databases)
#   schema                            CREATE -> schema_create; USAGE: lookup only
#   function/procedure                EXECUTE on SECURITY DEFINER -> secdef_funcs; EXECUTE on any other
#                                     function runs with the role's own rights, bounded by these counts
#   large object                      UPDATE, lo_compat_privileges -> other_writes; SELECT: read
#   tablespace                        CREATE -> other_writes
#   foreign-data wrapper / server     USAGE -> other_writes
#   parameter (15+)                   SET, ALTER SYSTEM -> other_writes
#   type/domain                       USAGE: harmless (lets the role use the type in objects it could only
#                                     create with CREATE, already counted)
#   language                          USAGE: harmless for the same reason (a function needs schema CREATE)
#   role membership                   -> set_role; role attributes -> role_attrs (REPLICATION covers
#                                     replication and slots; publications need database CREATE; subscriptions
#                                     need superuser or pg_create_subscription membership; event triggers
#                                     need superuser); ownership of anything -> owned
#   db_temp        may the role create TEMPORARY tables: information only. TEMPORARY is allowed, outside
#                  the guarantee: the guarantee covers persistent data. Temporary objects are session-scoped,
#                  never touch persistent data and vanish with the session; Postgres grants TEMPORARY to
#                  PUBLIC by default
PRODDB_SQL_TEMPLATE=$(cat <<'SQL'
WITH nonsys AS (
  SELECT oid, nspname FROM pg_namespace
  WHERE nspname <> 'information_schema' AND nspname NOT LIKE 'pg\_%'
), me AS (
  SELECT oid FROM pg_roles WHERE rolname = current_user
)
SELECT 'tools_check'
  || ' ro=' || current_setting('default_transaction_read_only')
  || ' db_create=' || has_database_privilege(current_user, current_database(), 'CREATE')::text
  || ' schema_create=' || (SELECT count(*) FROM nonsys n
                           WHERE has_schema_privilege(current_user, n.oid, 'CREATE'))::text
  || ' direct=' || (SELECT count(*) FROM information_schema.role_table_grants
                    WHERE grantee = current_user
                      AND privilege_type IN ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'TRIGGER', 'MAINTAIN'))::text
  || ' relations=' || (SELECT count(*) FROM pg_class c JOIN nonsys n ON n.oid = c.relnamespace
                       WHERE c.relkind IN ('r', 'p', 'v', 'm', 'f')
                         AND has_table_privilege(current_user, c.oid,
                                                 'INSERT, UPDATE, DELETE, TRUNCATE, TRIGGER'))::text
  || ' maintain=' || (CASE WHEN current_setting('server_version_num')::int >= 170000
                          THEN (SELECT count(*) FROM pg_class c JOIN nonsys n ON n.oid = c.relnamespace
                                WHERE c.relkind IN ('r', 'p', 'v', 'm', 'f')
                                  AND has_table_privilege(current_user, c.oid, 'MAINTAIN'))
                          ELSE 0 END)::text
  || ' sequences=' || (SELECT count(*) FROM pg_class c JOIN nonsys n ON n.oid = c.relnamespace
                       WHERE c.relkind = 'S'
                         AND has_sequence_privilege(current_user, c.oid, 'USAGE, UPDATE'))::text
  || ' secdef_funcs=' || (SELECT count(*) FROM pg_proc p JOIN nonsys n ON n.oid = p.pronamespace
                          WHERE p.prosecdef
                            AND has_function_privilege(current_user, p.oid, 'EXECUTE')
                            AND NOT (n.nspname || '.' || p.proname
                                       || '(' || pg_get_function_identity_arguments(p.oid) || ')'
                                     = ANY (ARRAY(SELECT btrim(a)
                                                  FROM unnest(string_to_array('__ALLOWED_FUNCS__', ';')) a))))::text
  || ' role_attrs=' || (SELECT (rolsuper OR rolcreaterole OR rolcreatedb OR rolreplication)::text
                        FROM pg_roles WHERE rolname = current_user)
  || ' set_role=' || (SELECT count(*) FROM pg_roles r
                      WHERE r.rolname <> current_user
                        AND r.rolname NOT IN ('pg_read_all_data', 'pg_read_all_settings', 'pg_read_all_stats',
                                              'pg_stat_scan_tables', 'pg_monitor')
                        AND pg_has_role(current_user, r.oid, 'MEMBER'))::text
  || ' owned=' || ((SELECT count(*) FROM pg_class c JOIN nonsys n ON n.oid = c.relnamespace
                     WHERE c.relowner = (SELECT oid FROM me))
                  + (SELECT count(*) FROM pg_proc p JOIN nonsys n ON n.oid = p.pronamespace
                     WHERE p.proowner = (SELECT oid FROM me))
                  + (SELECT count(*) FROM nonsys n JOIN pg_namespace ns ON ns.oid = n.oid
                     WHERE ns.nspowner = (SELECT oid FROM me))
                  + (SELECT count(*) FROM pg_type t JOIN nonsys n ON n.oid = t.typnamespace
                     WHERE t.typowner = (SELECT oid FROM me))
                  + (SELECT count(*) FROM pg_largeobject_metadata l
                     WHERE l.lomowner = (SELECT oid FROM me)))::text
  || ' columns=' || (SELECT count(*) FROM pg_class c JOIN nonsys n ON n.oid = c.relnamespace
                      WHERE c.relkind IN ('r', 'p', 'v', 'm', 'f')
                        AND has_any_column_privilege(current_user, c.oid, 'INSERT, UPDATE'))::text
  || ' other_writes=' || (
       (SELECT count(*) FROM pg_largeobject_metadata l, aclexplode(l.lomacl) a
        WHERE a.privilege_type = 'UPDATE' AND a.grantee IN (0, (SELECT oid FROM me)))
     + (CASE WHEN current_setting('lo_compat_privileges') = 'on' THEN 1 ELSE 0 END)
     + (SELECT count(*) FROM pg_tablespace t
        WHERE has_tablespace_privilege(current_user, t.oid, 'CREATE'))
     + (SELECT count(*) FROM pg_foreign_data_wrapper w
        WHERE has_foreign_data_wrapper_privilege(current_user, w.oid, 'USAGE'))
     + (SELECT count(*) FROM pg_foreign_server s
        WHERE has_server_privilege(current_user, s.oid, 'USAGE'))
     + (CASE WHEN current_setting('server_version_num')::int >= 150000
             THEN (xpath('/row/c/text()', query_to_xml(
                     'SELECT count(*) AS c FROM pg_catalog.pg_parameter_acl a
                      WHERE has_parameter_privilege(current_user, a.parname, ''ALTER SYSTEM'')
                         OR (has_parameter_privilege(current_user, a.parname, ''SET'')
                             AND NOT EXISTS (SELECT 1 FROM pg_catalog.pg_settings s
                                             WHERE s.name = a.parname AND s.context = ''user''))',
                     false, true, '')))[1]::text::int
             ELSE 0 END))::text
  || ' db_temp=' || has_database_privilege(current_user, current_database(), 'TEMPORARY')::text
  AS tools_check;
SQL
)

# Production logs, READ-ONLY (optional). One read of at most one entry under the read-only identity, e.g.
#   gcloud logging read 'severity>=ERROR' --project=<project> --limit=1 --freshness=1d --format=json
# Its output is discarded unread. Empty = SKIP.
# PRODDB_CMD / LOGS_CMD are trusted project config run by bash; set them in this file (reviewed in git), never
# from untrusted input. Safety comes from the read-only role, which this check verifies.
LOGS_CMD=''               # set here, reviewed in git; no environment override

FAILED=0

say() {
  # say <STATUS> <integration> <message>
  printf '%-10s %-10s %s\n' "$1" "$2" "$3"
  case "$1" in OK|SKIP) ;; *) FAILED=1 ;; esac
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

# classify_error <integration> <stderr-file> <what ran>: turns an error into a verdict without printing it.
classify_error() {
  local integ="$1" errf="$2" what="$3"
  if grep -Eqi 'password authentication failed|authentication failed|no password supplied|role ".*" does not exist|UNAUTHENTICATED|invalid_grant|reauthenticat|no active account|could not find default credentials|invalid.*credentials|token.*expired|credentials.*expired|ExpiredToken|InvalidClientTokenId' "$errf"; then
    say "REJECTED" "$integ" "the credential was refused: wrong or rotated password, revoked key, or the wrong identity active ($what)"
  elif grep -Eqi 'PERMISSION_DENIED|permission denied|not authorized|forbidden|AccessDenied|AuthorizationFailed|pg_hba\.conf' "$errf"; then
    say "DENIED" "$integ" "the credential works but lacks the permission for this read; see the runbook's identity step ($what)"
  elif grep -Eqi 'could not connect|connection refused|timeout expired|timed out|could not translate host|no route to host|name or service not known|Network is unreachable' "$errf"; then
    say "FAIL" "$integ" "no answer: is the database proxy running on the configured port, and is the host right? ($what)"
  else
    say "FAIL" "$integ" "the command failed with an error this script does not classify; run it by hand to see it ($what)"
  fi
}

check_prod_db() {
  if [ -z "$PRODDB_CMD" ]; then
    say "SKIP" prod-db "PRODDB_CMD is empty: production read-only access is not configured for this project"
    return
  fi
  if [ -n "$PRODDB_URL_VAR" ]; then
    need_var prod-db "$PRODDB_URL_VAR" || return
    check_shape prod-db "$PRODDB_URL_VAR" || return
  fi
  # The allowlist is pasted into the SQL as a literal, so it may hold only signature characters: no quote
  # can reach the SQL. (In the bracket expression, ']' first and '[' anywhere are literal.)
  if printf '%s' "$PRODDB_ALLOWED_FUNCS" | LC_ALL=C grep -q '[^][A-Za-z0-9_.,() ;]'; then
    say "BAD SHAPE" prod-db "PRODDB_ALLOWED_FUNCS may contain only exact signatures like schema.name(integer, text), separated by ';' (letters, digits, _ . , ( ) [ ] ; and spaces; no quotes)"
    return
  fi
  local sql errf out rc line key val ro reasons info
  sql="${PRODDB_SQL_TEMPLATE//__ALLOWED_FUNCS__/$PRODDB_ALLOWED_FUNCS}"
  errf="$(mktemp)"
  out="$(printf '%s\n' "$sql" \
    | PGCONNECT_TIMEOUT="$PRODDB_CONNECT_TIMEOUT" bash -c "$PRODDB_CMD" 2>"$errf")"
  rc=$?
  if [ "$rc" -eq 127 ]; then
    say "MISSING" prod-db "the first word of PRODDB_CMD is not an installed command (psql, the project's shell, ...)"
    rm -f "$errf"; return
  fi
  if [ "$rc" -ne 0 ] || grep -Eq '(ERROR|FATAL|error):' "$errf"; then
    classify_error prod-db "$errf" "the privilege SELECT"
    rm -f "$errf"; return
  fi
  rm -f "$errf"
  line="$(printf '%s\n' "$out" | grep -E 'tools_check ro=' | head -1)"
  if [ -z "$line" ]; then
    say "FAIL" prod-db "connected, but the privilege SELECT returned nothing readable: PRODDB_CMD must run SQL from stdin (psql, or the framework's dbshell)"
    return
  fi
  field() { printf '%s\n' "$line" | sed -n "s/.* $1=\([^ |]*\).*/\1/p"; }
  ro="$(field ro)"
  for key in db_create schema_create direct relations maintain columns sequences secdef_funcs role_attrs set_role owned other_writes; do
    if [ -z "$(field "$key")" ]; then
      say "FAIL" prod-db "the privilege SELECT came back without '$key': the result is incomplete, so nothing is proven"
      return
    fi
  done
  reasons=""
  # a counter that is not exactly 0 is a write path
  for key in schema_create direct relations maintain columns sequences secdef_funcs set_role owned other_writes; do
    val="$(field "$key")"
    [ "$val" = "0" ] || reasons="$reasons $key=$val"
  done
  # a flag that is not exactly false is a write path
  for key in db_create role_attrs; do
    val="$(field "$key")"
    [ "$val" = "false" ] || reasons="$reasons $key=$val"
  done
  info="db_temp=$(field db_temp): allowed, outside the guarantee: the guarantee covers persistent data"
  if [ -n "$reasons" ]; then
    say "WRITABLE" prod-db "the role has a write path into production:$reasons ($info). Stop using it; ask the admin to run the runbook's database-role step"
  elif [ "$ro" = "on" ]; then
    say "OK" prod-db "read-only default on; no write privilege on any relation, column, sequence, schema, large object, tablespace, foreign server or wrapper, parameter or the database; no SECURITY DEFINER function outside PRODDB_ALLOWED_FUNCS; no other role memberships; owns nothing ($info)"
  elif [ "$ro" = "off" ]; then
    say "READ-ONLY-DEFAULT-OFF" prod-db "no write privilege found, but default_transaction_read_only is off: not ready. Ask the admin for ALTER ROLE ... SET default_transaction_read_only = on"
  else
    say "FAIL" prod-db "could not read default_transaction_read_only from the result"
  fi
}

check_logs() {
  if [ -z "$LOGS_CMD" ]; then
    say "SKIP" logs "LOGS_CMD is empty: production log reading is not configured for this project"
    return
  fi
  case "$LOGS_CMD" in
    *limit*) ;;
    *) say "BAD SHAPE" logs "LOGS_CMD has no --limit; the check reads one entry, so add --limit=1"; return ;;
  esac
  local errf rc
  errf="$(mktemp)"
  bash -c "$LOGS_CMD" >/dev/null 2>"$errf"
  rc=$?
  if [ "$rc" -eq 127 ]; then
    say "MISSING" logs "the first word of LOGS_CMD is not an installed command (gcloud, aws, az, ...)"
  elif [ "$rc" -ne 0 ]; then
    classify_error logs "$errf" "one log read"
  else
    say "OK" logs "one log read works under the configured identity"
  fi
  rm -f "$errf"
}

if ! command -v curl >/dev/null 2>&1; then
  say "MISSING" curl "curl is not installed; the HTTP checks cannot run"
fi

for integration in $CHECKS; do
  case "$integration" in
    github)    check_github ;;
    bitbucket) check_bitbucket ;;
    jira)      check_jira ;;
    prod-db)   check_prod_db ;;
    logs)      check_logs ;;
    *)         say "FAIL" "$integration" "no check defined for this integration in tools-check.sh" ;;
  esac
done

exit "$FAILED"
