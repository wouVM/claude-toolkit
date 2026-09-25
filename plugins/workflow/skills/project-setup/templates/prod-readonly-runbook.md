# Read-only production access for Claude sessions (<PROJECT-NAME>)

Goal: a Claude session on a PM's machine can READ production (database rows, logs) to scope tickets
and diagnose, and can NEVER write. Two independent layers make that true:

1. **A cloud identity that can only read.** It can open a database connection and read logs; it
   cannot change infrastructure and cannot read the read-write database password.
2. **A database role that can only read.** SELECT grants and nothing else, plus
   `default_transaction_read_only = on`. Even with a working connection, the database itself refuses
   any write.

The PM's own full login stays out of the session's reach: it is revoked on the machine, and every
file holding a read-write password is blanked. Without that step, layers 1 and 2 are decoration.

Who does what:

| Step | Who | What |
|---|---|---|
| 1-4 | ADMIN (an engineer with admin rights on production) | Create the read-only identity, the read-only database role, the read-only connection secret, and hand the PM a key |
| 5-7 | PM (on their own machine) | Install the tools, activate the read-only config, revoke their own login, blank read-write passwords |
| 8 | PM, then Claude | Verify from the privilege catalogue that the role cannot write (no write is ever attempted), record it in CLAUDE.md, run the tools check |

Claude never runs steps 1-7 itself: every one of them writes to production IAM, the database, or the
secret store, which is a human's act. It can explain each step and check the result afterwards.

Fill in before handing this out (the admin knows these):

- `<CLOUD-PROJECT>`: the production cloud project / account / subscription
- `<DB-INSTANCE>`: the database instance (for a proxy: its full connection name)
- `<DATABASE>`: the database name
- `<APP-DB-ROLE>`: the role the application connects as today (owns the tables)
- `<RO-IDENTITY>`: the name of the new read-only identity, e.g. `agent-readonly`
- `<RO-DB-ROLE>`: the name of the new read-only database role, e.g. `<project>_readonly`
- `<RW-SECRET>`: the secret that holds the application's read-write connection settings today
- `<RO-SECRET>`: the name of the new read-only connection secret, e.g. `<RW-SECRET>_readonly`
- `<PROXY-PORT>`: the local port the PM's database proxy listens on
- `<KEY-FILE>`: where the identity's key lives on the PM's machine, outside every repo

## 1. ADMIN: the read-only identity

Create a dedicated identity `<RO-IDENTITY>` in `<CLOUD-PROJECT>` for agent sessions (a service
account, an IAM role, a managed identity). Grant it exactly:

- **connect to `<DB-INSTANCE>`** (through the provider's proxy or IAM connection), which
  grants no rights INSIDE the database;
- **read logs** for the production project;
- **read the one read-only secret** from step 3, and no other secret.

Do NOT grant: any editor/owner/admin role, database-admin roles, or read access to `<RW-SECRET>`.
A broad "viewer" role is acceptable only if you have checked what it exposes (storage buckets with
personal data, for example); the narrow roles above are enough to scope tickets.

Verify: list the identity's roles and confirm the list is exactly what you granted.

## 2. ADMIN: the read-only database role (the layer that actually stops writes)

Connect once as `<APP-DB-ROLE>` (or an admin), then create a login role that can only SELECT. The
Postgres form:

```sql
-- a long random password; it goes into the read-only secret in step 3 and nowhere else.
-- The NO... attributes are Postgres's defaults, spelled out so nobody "fixes" them later.
CREATE ROLE <RO-DB-ROLE> LOGIN PASSWORD '<RO-PASSWORD>'
  NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
-- every session of this role starts read-only
ALTER ROLE <RO-DB-ROLE> SET default_transaction_read_only = on;
GRANT CONNECT ON DATABASE "<DATABASE>" TO <RO-DB-ROLE>;
REVOKE CREATE ON DATABASE "<DATABASE>" FROM <RO-DB-ROLE>;
-- the role owns nothing; if it ever did, hand it back to the application role
REASSIGN OWNED BY <RO-DB-ROLE> TO "<APP-DB-ROLE>";

-- every non-system schema (a multi-tenant app has one per tenant)
DO $$
DECLARE s text;
BEGIN
  FOR s IN
    SELECT nspname FROM pg_namespace
    WHERE nspname <> 'information_schema' AND nspname NOT LIKE 'pg\_%'
  LOOP
    EXECUTE format('GRANT USAGE ON SCHEMA %I TO <RO-DB-ROLE>', s);
    EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO <RO-DB-ROLE>', s);
    -- SELECT only on sequences: it reads the current value. Never USAGE or UPDATE, which advance
    -- or set it (nextval / setval) and are writes.
    EXECUTE format('GRANT SELECT ON ALL SEQUENCES IN SCHEMA %I TO <RO-DB-ROLE>', s);
    EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE "<APP-DB-ROLE>" IN SCHEMA %I GRANT SELECT ON TABLES TO <RO-DB-ROLE>', s);
    EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE "<APP-DB-ROLE>" IN SCHEMA %I GRANT SELECT ON SEQUENCES TO <RO-DB-ROLE>', s);
  END LOOP;
END $$;
```

Never `GRANT` another role to `<RO-DB-ROLE>`: a membership hands it that role's rights, or lets it
`SET ROLE` to them. The tools check counts every membership as a write path (`set_role`), except the
five predefined read-only roles `pg_read_all_data`, `pg_read_all_settings`, `pg_read_all_stats`,
`pg_stat_scan_tables` and `pg_monitor`. `GRANT pg_read_all_data TO <RO-DB-ROLE>` (Postgres 14 and
later) is an acceptable alternative to the per-schema grant loop and covers new schemas too, with
one cost: it reads every table, and a per-table REVOKE cannot carve the secret-holding ones out.

`PRODDB_CMD` / `LOGS_CMD` are trusted project config run by bash; set them in `scripts/tools-check.sh`
(reviewed in git), never from untrusted input. Safety comes from the read-only role, which the check
verifies.

Why both the grants and the read-only default: the grants are the wall (no INSERT, UPDATE, DELETE,
TRUNCATE, TRIGGER, MAINTAIN, column-level or DDL privilege anywhere; step 8's table lists every kind). The default makes the first write statement of any
session fail loudly. A session can switch the default off with `SET`, so the grants are the part that
must be right, and the tools check treats a missing default as a failure too.

**Close the PUBLIC doors before activation.** Postgres gives some privileges to PUBLIC, meaning every
role, and a REVOKE from `<RO-DB-ROLE>` alone does not remove what it holds through PUBLIC:

- `CREATE` on the `public` schema (the default before Postgres 15; a database upgraded from an older
  version keeps it). The tools check reports this as WRITABLE (`schema_create`). Revoke it from
  PUBLIC, and grant it back to the application role if it creates objects in `public` without owning
  the schema (test on staging: this changes the rule for every role):

  ```sql
  REVOKE CREATE ON SCHEMA public FROM PUBLIC;
  GRANT CREATE ON SCHEMA public TO "<APP-DB-ROLE>";   -- only if the app needs it and does not own public
  ```

  Any other schema where `schema_create` counts: `REVOKE CREATE ON SCHEMA <schema> FROM PUBLIC, <RO-DB-ROLE>;`.
- `EXECUTE` on every new function. That matters for functions declared `SECURITY DEFINER`: they run
  with their OWNER's rights, so any one of them the role may call is a write path, whatever its grants.
  Inventory them:

  ```sql
  SELECT n.nspname || '.' || p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')'
           AS signature, pg_get_userbyid(p.proowner) AS runs_as
  FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE p.prosecdef AND n.nspname <> 'information_schema' AND n.nspname NOT LIKE 'pg\_%'
    AND has_function_privilege('<RO-DB-ROLE>', p.oid, 'EXECUTE');
  ```

  For each one: if it can write, `REVOKE EXECUTE ON FUNCTION <signature> FROM PUBLIC, <RO-DB-ROLE>;`
  and grant it back to the roles that call it. If you have read it and it only reads, copy its
  `signature` column exactly, arguments included, into `PRODDB_ALLOWED_FUNCS` in
  `scripts/tools-check.sh`, entries separated by `;` (e.g.
  `public.report_totals(integer); billing.summary(date, date)`). The approval is per signature: an
  overload with other arguments is a different function and still counts until you review it too. A
  signature with a quote in it (a quoted identifier) cannot be approved; revoke it or rename it. That
  list is your signature that each entry was reviewed.
- `TEMPORARY` on each database: allowed, outside the guarantee: the guarantee covers persistent
  data. Temporary objects are session-scoped, never touch persistent data and vanish with the
  session, and Postgres grants
  TEMPORARY to PUBLIC by default, so the check reports it as information (`db_temp`) and it is not a
  requirement. Optional, only if your policy wants it: `REVOKE TEMPORARY ON DATABASE "<DATABASE>"
  FROM PUBLIC;` plus a grant back to the application role.

Decide whether SELECT on EVERY table is right. Tables that hold secrets (password hashes, API or
OAuth tokens, signing keys) should be revoked again after the loop:
`REVOKE SELECT ON <schema>.<table> FROM <RO-DB-ROLE>;`. Rows about people stay readable, which is the
point of scoping from production; the CLAUDE.md rules keep them out of tickets and chat.

**Re-run the DO block whenever a new schema appears** (a new tenant, a new app module with its own
schema). `ALTER DEFAULT PRIVILEGES` covers new tables and sequences in schemas that already exist, and
only those created by `<APP-DB-ROLE>`; it does not cover new schemas.
Add the DO block to the tenant-provisioning runbook, or the read-only role quietly stops seeing new
tenants.

Other engines: MySQL has no per-user read-only default, so the wall is `GRANT SELECT ON <db>.*`
alone and the step 8 check matters more; SQL Server uses the `db_datareader` role and no writer
role. The verification in step 8 is the same idea for every engine: read the engine's privilege
catalogue (MySQL `SHOW GRANTS`, SQL Server `fn_my_permissions`) and confirm no write privilege.
Never attempt a write to find out.

## 3. ADMIN: the read-only connection secret

Publish the connection settings the PM's tools need, with the database user and password swapped
for `<RO-DB-ROLE>` and `<RO-PASSWORD>`, as a NEW secret `<RO-SECRET>`. Only `<RO-IDENTITY>` may
read it. Do not put the password in a repo, a ticket, a chat, or an e-mail: the secret store is the
only place it lives.

Verify: the secret's access policy lists only `<RO-IDENTITY>` (plus admins).

## 4. ADMIN: hand the PM the identity

Give the PM a credential for `<RO-IDENTITY>` (a key file, or whatever your cloud's workload identity
scheme is). The PM stores it at `<KEY-FILE>`, owner-read only (`chmod 600`), outside every repo.

## 5. PM: install the tools

- The cloud CLI (for logs and for fetching the secret).
- The database proxy if the database is private (most managed databases are).
- A client: `psql` for Postgres, or the project's own shell (for example a framework `manage.py
  shell` pointed at the read-only settings file). The tools check's `prod-db` needs a client that
  reads SQL on stdin: `psql`, or the framework's `dbshell`.

## 6. PM: activate the read-only config and revoke your own login

- Activate `<RO-IDENTITY>` as the cloud CLI's active identity, with its own named configuration so
  switching back is explicit.
- **Revoke your personal cloud login AND any application-default credentials.** These are often two
  separate tokens on disk; the second one is what libraries and proxies pick up, whatever the active
  CLI configuration says. Point the application default at `<KEY-FILE>` instead.
- Start the proxy for `<DB-INSTANCE>` on `<PROXY-PORT>` with `<KEY-FILE>`, not with your own login.
  A proxy started earlier under your own login dies at its next token refresh once that login is
  revoked; restart it.

When you personally need write access: log in, do the work, revoke again, reactivate the read-only
configuration. That is the whole switch, and it is deliberately manual.

## 7. PM: remove read-write credentials from the machine

The read-only identity CAN open a database connection. Any file that still holds `<APP-DB-ROLE>`'s
password turns that connection into full write access and walks around everything above. Find and
blank them (names only, never print the values):

- `.env` / `.env.prod` / settings files in every checkout and worktree of the project
- `~/.pgpass` or the engine's equivalent, and saved connections in database GUIs
- shell profiles (`~/.zshrc`, `~/.bashrc`) exporting a production URL or password
- scratch copies of `<RW-SECRET>` left by earlier diagnostic sessions (`/tmp`, `~/Downloads`)

A staging/beta password may stay if `<RO-IDENTITY>` has no access to that environment at all.

Honest limit: this protects production from a session using YOUR credentials, because they are no
longer on the machine. It does not protect against forgetting to revoke after a write session. A
separate OS user for agent sessions closes that gap too.

## 8. PM: verify the role cannot write, then record it

Verification reads the privilege catalogue. It never attempts a write, not even one that "cannot
change anything": a check that writes to production is exactly the habit this setup exists to stop.

As `<RO-DB-ROLE>`, through the same command Claude will use. "Non-system" means every schema except
`information_schema` and the reserved `pg_*` ones.

```sql
SELECT count(*) FROM <some-table>;               -- works: the role can read
SHOW default_transaction_read_only;              -- must be: on

-- may it create schemas in the database, or objects in any non-system schema: must be f and 0
SELECT has_database_privilege(current_user, current_database(), 'CREATE');
SELECT count(*) FROM pg_namespace n
WHERE n.nspname <> 'information_schema' AND n.nspname NOT LIKE 'pg\_%'
  AND has_schema_privilege(current_user, n.oid, 'CREATE');

-- write grants made to the role directly: must be 0
SELECT count(*) FROM information_schema.role_table_grants
WHERE grantee = current_user
  AND privilege_type IN ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'TRIGGER', 'MAINTAIN');

-- tables, partitioned tables, views, materialized views, foreign tables it can write by ANY route
-- (an inherited role, PUBLIC, ownership, superuser), which the query above cannot see: must be 0
SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname <> 'information_schema' AND n.nspname NOT LIKE 'pg\_%'
  AND c.relkind IN ('r', 'p', 'v', 'm', 'f')
  AND has_table_privilege(current_user, c.oid, 'INSERT, UPDATE, DELETE, TRUNCATE, TRIGGER');

-- MAINTAIN (Postgres 17+: VACUUM, ANALYZE, REINDEX, REFRESH MATERIALIZED VIEW, LOCK TABLE) on any
-- relation: must be 0. Before 17 the privilege does not exist and this prints 0 without evaluating it.
SELECT CASE WHEN current_setting('server_version_num')::int >= 170000
            THEN (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
                  WHERE n.nspname <> 'information_schema' AND n.nspname NOT LIKE 'pg\_%'
                    AND c.relkind IN ('r', 'p', 'v', 'm', 'f')
                    AND has_table_privilege(current_user, c.oid, 'MAINTAIN'))
            ELSE 0 END;

-- sequences it can advance or set: must be 0
SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname <> 'information_schema' AND n.nspname NOT LIKE 'pg\_%'
  AND c.relkind = 'S' AND has_sequence_privilege(current_user, c.oid, 'USAGE, UPDATE');

-- SECURITY DEFINER functions it may run, one row per exact signature: every row listed here must
-- appear, character for character, in PRODDB_ALLOWED_FUNCS (no rows at all is the simplest pass)
SELECT n.nspname || '.' || p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')' AS signature
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE p.prosecdef AND n.nspname <> 'information_schema' AND n.nspname NOT LIKE 'pg\_%'
  AND has_function_privilege(current_user, p.oid, 'EXECUTE')
ORDER BY 1;

-- column-level INSERT or UPDATE on any relation (a column grant is invisible to the query above): must be 0
SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname <> 'information_schema' AND n.nspname NOT LIKE 'pg\_%'
  AND c.relkind IN ('r', 'p', 'v', 'm', 'f')
  AND has_any_column_privilege(current_user, c.oid, 'INSERT, UPDATE');

-- the other write paths, one row per kind (other_writes is their sum): every n must be 0
WITH me AS (SELECT oid FROM pg_roles WHERE rolname = current_user)
SELECT 'large objects with UPDATE for the role or PUBLIC' AS kind, count(*) AS n
  FROM pg_largeobject_metadata l, aclexplode(l.lomacl) a
  WHERE a.privilege_type = 'UPDATE' AND a.grantee IN (0, (SELECT oid FROM me))
UNION ALL SELECT 'lo_compat_privileges on (large-object checks off)',
  CASE WHEN current_setting('lo_compat_privileges') = 'on' THEN 1 ELSE 0 END
UNION ALL SELECT 'tablespaces with CREATE', count(*) FROM pg_tablespace t
  WHERE has_tablespace_privilege(current_user, t.oid, 'CREATE')
UNION ALL SELECT 'foreign-data wrappers with USAGE', count(*) FROM pg_foreign_data_wrapper w
  WHERE has_foreign_data_wrapper_privilege(current_user, w.oid, 'USAGE')
UNION ALL SELECT 'foreign servers with USAGE', count(*) FROM pg_foreign_server s
  WHERE has_server_privilege(current_user, s.oid, 'USAGE');

-- Postgres 15 and later only (pg_parameter_acl does not exist on 14; skip this there):
-- parameters it may ALTER SYSTEM, or SET where a plain user cannot: must be 0
SELECT count(*) FROM pg_parameter_acl a
WHERE has_parameter_privilege(current_user, a.parname, 'ALTER SYSTEM')
   OR (has_parameter_privilege(current_user, a.parname, 'SET')
       AND NOT EXISTS (SELECT 1 FROM pg_settings s WHERE s.name = a.parname AND s.context = 'user'));

-- non-system objects the role owns (an owner can ALTER or DROP them whatever the grants say): must be 0
WITH me AS (SELECT oid FROM pg_roles WHERE rolname = current_user),
     nonsys AS (SELECT oid FROM pg_namespace
                WHERE nspname <> 'information_schema' AND nspname NOT LIKE 'pg\_%')
SELECT (SELECT count(*) FROM pg_class WHERE relowner = (SELECT oid FROM me)
          AND relnamespace IN (SELECT oid FROM nonsys))
     + (SELECT count(*) FROM pg_proc WHERE proowner = (SELECT oid FROM me)
          AND pronamespace IN (SELECT oid FROM nonsys))
     + (SELECT count(*) FROM pg_namespace WHERE nspowner = (SELECT oid FROM me)
          AND oid IN (SELECT oid FROM nonsys))
     + (SELECT count(*) FROM pg_type WHERE typowner = (SELECT oid FROM me)
          AND typnamespace IN (SELECT oid FROM nonsys))
     + (SELECT count(*) FROM pg_largeobject_metadata WHERE lomowner = (SELECT oid FROM me));

-- powerful role attributes: must be f
SELECT rolsuper OR rolcreaterole OR rolcreatedb OR rolreplication FROM pg_roles WHERE rolname = current_user;
-- membership in any other role, inherited or not (set_role): must be 0. Only five predefined roles
-- that can only read by design are not counted; every other one is, pg_write_all_data included.
SELECT count(*) FROM pg_roles r
WHERE r.rolname <> current_user
  AND r.rolname NOT IN ('pg_read_all_data', 'pg_read_all_settings', 'pg_read_all_stats',
                        'pg_stat_scan_tables', 'pg_monitor')
  AND pg_has_role(current_user, r.oid, 'MEMBER');
```

Compare the SECURITY DEFINER list by hand against `PRODDB_ALLOWED_FUNCS`: the check passes on that
point only when every listed signature is in the allowlist exactly, and each entry there is one you
have read.

Pass means exactly this (a `SECURITY DEFINER` function counts unless its exact signature is in
`PRODDB_ALLOWED_FUNCS`): `default_transaction_read_only` is `on`; `db_create` is false;
`schema_create`, `direct`, `relations`, `maintain`, `columns`, `sequences`, `secdef_funcs`,
`set_role`, `owned` and `other_writes` are all 0; `role_attrs` is false; and `bash
scripts/tools-check.sh` prints OK for `prod-db`. The tools check runs these same queries as one SELECT
once `PRODDB_CMD` is set, and prints the name of every value that fails.

**What counts as a write path.** Every kind of object a `GRANT` can target in Postgres 14-17, and how
the check treats it:

| Object | Privilege | Counted in | Why |
|---|---|---|---|
| table, view, materialized view, foreign table | INSERT, UPDATE, DELETE, TRUNCATE, TRIGGER | `relations`, `direct` | writes rows or adds triggers |
| same | MAINTAIN (17+) | `maintain` | VACUUM, REINDEX, REFRESH, LOCK |
| same, and columns | REFERENCES | not counted | an FK needs a table the role owns or may create, both counted |
| column | INSERT, UPDATE | `columns` | column grants are invisible to table-level checks |
| sequence | USAGE, UPDATE | `sequences` | nextval / setval |
| database | CREATE | `db_create` | new schemas, publications |
| database | TEMPORARY | `db_temp`, information | allowed, outside the guarantee: the guarantee covers persistent data |
| database | CONNECT | not counted | no write; see other databases below |
| schema | CREATE | `schema_create` | new objects |
| function, procedure | EXECUTE on SECURITY DEFINER | `secdef_funcs` | runs with the owner's rights |
| function, procedure | EXECUTE on the rest | not counted | runs with the role's own rights, which these counts bound |
| large object | UPDATE; `lo_compat_privileges = on` | `other_writes` | writes the object; the setting switches checks off |
| tablespace | CREATE | `other_writes` | objects in that tablespace |
| foreign-data wrapper | USAGE | `other_writes` | CREATE SERVER |
| foreign server | USAGE | `other_writes` | CREATE USER MAPPING, foreign tables |
| parameter (15+) | ALTER SYSTEM; SET on a non-user parameter | `other_writes` | persistent server config; privileged session settings |
| type, domain | USAGE | not counted | using a type needs CREATE somewhere, already counted |
| language | USAGE | not counted | a function needs schema CREATE, already counted |
| role | membership; SUPERUSER, CREATEROLE, CREATEDB, REPLICATION | `set_role`, `role_attrs` | another role's rights; replication, slots, subscriptions and event triggers need these |
| anything | ownership | `owned` | an owner can ALTER or DROP |

**Other databases.** The check reads the database `PRODDB_CMD` connects to. PUBLIC has CONNECT on
every database by default, and the role's grants can differ in each. Either run the check against each
database the role can connect to, or `REVOKE CONNECT ON DATABASE <other> FROM PUBLIC` where it has no
business.

`WRITABLE` names the counter that is not zero: stop, back to step 2. `READ-ONLY-DEFAULT-OFF` is also a
failure: the `ALTER ROLE ... SET default_transaction_read_only = on` line was not applied.

Also verify the identity: the cloud CLI lists only `<RO-IDENTITY>` as active; reading `<RW-SECRET>`
is DENIED while reading `<RO-SECRET>` works; the application-default credentials file is gone; one
log read works:

```bash
<LOG-COMMAND> --limit=1
```

Then run `bash scripts/tools-check.sh`: `prod-db` and `logs` should both print OK. Paste the result
and today's date into the CLAUDE.md "Reading production" section and flip its status line to ACTIVE.

---

## EXAMPLE (GCP, Cloud SQL for Postgres): one worked setup

Everything in this section is an EXAMPLE. Replace every value; the names below are illustrative, not
a real project.

```bash
# --- 1. ADMIN: identity ---
PROJECT=example-prod-123456
SA=agent-readonly@$PROJECT.iam.gserviceaccount.com
gcloud config set project $PROJECT
gcloud iam service-accounts create agent-readonly --display-name="Claude agent, read-only"
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:$SA" --role="roles/cloudsql.client"
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:$SA" --role="roles/logging.viewer"
# broader alternative that also reads other services' config: roles/viewer (it covers logs too)
gcloud projects get-iam-policy $PROJECT --flatten="bindings[].members" \
  --filter="bindings.members:$SA" --format="value(bindings.role)"   # prints exactly the roles above

# --- 2. ADMIN: role, via the proxy as the app user ---
cloud-sql-proxy --port 5433 $PROJECT:europe-west1:example-db &
psql "host=127.0.0.1 port=5433 dbname=example user=example-app"      # then run the SQL from step 2

# --- 3. ADMIN: read-only secret (never echo it; the temp file is owner-only and always removed) ---
OLD_UMASK=$(umask); umask 077
RO_ENV=$(mktemp) && chmod 600 "$RO_ENV"
gcloud secrets versions access latest --secret=example_settings \
  | sed -e 's/^DB_USER=.*/DB_USER=example_readonly/' \
        -e 's/^DB_PASSWORD=.*/DB_PASSWORD=<RO-PASSWORD>/' > "$RO_ENV"
gcloud secrets create example_settings_readonly --data-file="$RO_ENV"
rm -f "$RO_ENV"; umask "$OLD_UMASK"
gcloud secrets add-iam-policy-binding example_settings_readonly \
  --member="serviceAccount:$SA" --role="roles/secretmanager.secretAccessor"

# --- 4. ADMIN: key for the PM (org policy may forbid keys; then use your workload identity scheme) ---
gcloud iam service-accounts keys create agent-readonly.json --iam-account=$SA

# --- 6. PM: activate, revoke, repoint ---
mkdir -p ~/.config/gcloud && mv agent-readonly.json ~/.config/gcloud/ && chmod 600 ~/.config/gcloud/agent-readonly.json
gcloud config configurations create readonly
gcloud auth activate-service-account --key-file=$HOME/.config/gcloud/agent-readonly.json
gcloud config set project $PROJECT
gcloud auth revoke you@example.com              # your personal login
gcloud auth application-default revoke          # the SECOND token that proxies and libraries use
echo 'export GOOGLE_APPLICATION_CREDENTIALS=$HOME/.config/gcloud/agent-readonly.json' >> ~/.zshrc
cloud-sql-proxy --credentials-file $HOME/.config/gcloud/agent-readonly.json \
  --port 5433 $PROJECT:europe-west1:example-db > /tmp/cloud-sql-proxy.log 2>&1 &

# --- 8. PM: verify (run the step 8 SQL through the proxy first) ---
gcloud auth list                                                   # only the service account is active
gcloud secrets versions access latest --secret=example_settings    # PERMISSION_DENIED
gcloud secrets versions access latest --secret=example_settings_readonly > /dev/null && echo readable
ls ~/.config/gcloud/application_default_credentials.json           # No such file
gcloud logging read 'severity>=ERROR' --project=$PROJECT --limit=1 --freshness=1d --format=json > /dev/null && echo logs-ok
```

Personal write access, when needed: `gcloud config configurations activate default && gcloud auth
login` (plus `gcloud auth application-default login` if a script needs it), do the work, revoke both,
`gcloud config configurations activate readonly`.
