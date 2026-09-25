# PM day one: set up Claude to work on your CVT project

This guide is for a product manager on a CVT project. At the end of it, Claude can do for your
project what it does for FCB:

- read the code, so it can tell you how the product behaves today, with proof;
- read the production database and the logs, and never change them;
- talk through a requirement with you (`workflow:ask`);
- turn a request (an e-mail, a complaint, a sheet row) into a fully scoped ticket
  (`workflow:intake`, which runs `workflow:ticket-format` and then `workflow:spec-sharpen` for you);
- leave the ticket as a draft for a person to sign.

Each step says who does it and roughly how long it takes. PM means you. Admin means whoever
manages your cloud account and database. Engineer means a developer on the project. Steps
marked [admin] or [engineer] are ones you ask for; you cannot do them yourself.

Total time: about half a day, most of it waiting for the admin.

## 1. Install Claude Code and the toolkit (PM, 15 minutes)

Install Claude Code on your laptop. On a Mac, open Terminal and run:

```
curl -fsSL https://claude.ai/install.sh | bash
```

Then type `claude` and log in with your CVT claude.ai account.

Inside Claude Code, add the toolkit and install the `workflow` plugin:

```
/plugin marketplace add wouVM/claude-toolkit
/plugin install workflow@claude-toolkit
```

You need read access to the toolkit repository on GitHub. If the first command fails with an
access error, ask the engineer to add you.

If your project repo was already set up with "team auto-install" (step 4), this happens by
itself the first time you open the repo in Claude Code and trust the folder. Run the two
commands anyway; they do nothing if the plugin is already there.

Check: type `/workflow:` and you should see a list of skills such as `workflow:intake`.

## 2. Connect Jira and your inbox (PM, 10 minutes)

Claude reads your tracker and your mail through claude.ai connectors. Open claude.ai, go to
Settings, then Connectors, and connect:

- Atlassian (Jira). This one is required. Without it, `workflow:intake` stops before it files
  anything, on purpose: it cannot check for duplicates in a tracker it cannot read.
- Gmail, Google Drive and Google Sheets, if requests reach you by mail or in a shared sheet.

Log in with your work account, not a personal one. Then restart Claude Code and type `/mcp`.
Each connector you added should be listed as connected. If one says it needs authorisation,
repeat the connect step for it.

## 3. Get the code (PM with engineer, 15 minutes)

Ask the engineer which repositories make up the project and for read access to each. Then
clone them into one folder, for example:

```
mkdir -p ~/code && cd ~/code
git clone <repo URL from the engineer>
```

You only need to read the code. You will not push changes, and you do not need a local build
that runs. Open Claude Code from inside the project folder (`cd` into it, then `claude`).

## 4. Run project setup (PM with engineer, 30 minutes)

In Claude Code, inside the project folder, run:

```
/workflow:project-setup
```

It asks which pieces to add. If an engineer has already run it for this repo, most pieces are
there and it only proposes what is missing. Answer like this:

- CLAUDE.md conventions: yes. This is the file that tells Claude how the project works.
- Team auto-install: yes. Everyone who clones the repo then gets the toolkit.
- Ticket pickup policy (`.claude/pickup.json`): yes. It asks for the Jira project key, the
  status a new ticket starts in (for example "Triage"), and the status that means "signed, ready
  to build" (for example "Ready for Dev"). Copy the status names exactly as Jira spells them.
  When it asks who owns each kind of fix, name the engineer, and leave the autonomy at `plan`.
  That means Claude may write a plan for a ticket but never code.
- Premises location: keep `"sidecar"`, the default. That is the company ticket format: the
  technical evidence goes in a separate brief for the builder, and the ticket body keeps one
  pointer line to it.
- Tools check: yes.
- Production read-only access (DB and logs): yes. It adds two sections to CLAUDE.md, "Reading
  production (READ-ONLY)" and "Reading logs", both marked NOT ACTIVE for now. It writes the
  runbook for step 5 to `docs/runbooks/prod-readonly-access.md`. And it adds the `prod-db` and
  `logs` checks to the tools check, which print SKIP until step 5 is done.
- The judge rubric, the role fence, the testing rule and the completion check: leave these to
  the engineer. Say "skip" if you are unsure.

When it finishes, it lists the files it wrote. Ask the engineer to review and commit them, so
the setup reaches everyone on the project.

## 5. Read-only access to production and logs (admin 1 hour, PM 45 minutes)

Claude should be able to look at real data and real logs, and it must not be able to change
anything. That rule is enforced by the accounts themselves, not by asking Claude to be careful.
Follow the runbook project setup wrote: `docs/runbooks/prod-readonly-access.md`. Claude does not
run any of its steps for you, but it can explain each one and check the result afterwards.

[admin] Runbook steps 1 to 4:

- a read-only cloud identity for Claude that can connect to the database, read logs and read
  one secret, and nothing else;
- a database login that can only SELECT, and whose every session starts read-only;
- the connection settings for that login in a new secret only that identity can read;
- the identity's key file, sent to the PM through a secure channel, never by e-mail or chat.

PM, runbook steps 5 to 7, on your own laptop:

- install the tools the runbook names (the cloud command line, the database connection tool);
- switch to the read-only identity, and log your own cloud account out, including its
  "application default" login, which is a second, separate one;
- blank every production password on the laptop that could write: settings files, saved
  database connections, lines in your shell profile.

PM, runbook step 8: check that Claude cannot write. This never tries a write on production, not even
a test one. It reads the database's own list of permissions instead. Pass means exactly this:
`default_transaction_read_only` is `on`; `db_create` is false; `schema_create`, `direct`,
`relations`, `maintain`, `columns`, `sequences`, `secdef_funcs`, `set_role`, `owned` and
`other_writes` are all 0; `role_attrs` is false; and `bash scripts/tools-check.sh` prints OK for
`prod-db`.

Then let Claude record the result and today's date in the CLAUDE.md section "Reading production
(READ-ONLY)", switch its status to ACTIVE, and fill in `PRODDB_CMD` and `LOGS_CMD` in the tools
check. In step 6, `prod-db` and `logs` should both print OK.

Never log in with your own personal cloud account to "help" Claude read something. The
read-only identity is the only access Claude gets.

## 6. Run the tools check (PM, 5 minutes)

From the project folder, in Terminal:

```
bash scripts/tools-check.sh
```

It prints one line per check. What the words mean:

- OK: works.
- SKIP: not set up for this project. Not a failure.
- MISSING: a setting or a tool is not there in this terminal. Usually a line missing from your
  shell profile, or a program that is not installed.
- BAD SHAPE: the setting is there but broken, for example a stray space or quote.
- 401 or REJECTED: the service refused the credential.
- 403 or DENIED: the credential works but lacks a permission. Ask the admin to add it.
- FAIL: the service could not be reached, or gave an error the check does not recognise.
- WRITABLE (`prod-db` only): the database login has a way to write to production (the line says
  which). Stop using it and tell the admin at once.
- READ-ONLY-DEFAULT-OFF (`prod-db` only): a failure. No way to write was found, but the read-only
  default is missing. Pass it to the admin; production reading stays off until it prints OK.

It never prints a password or token, so you can paste its output to the engineer. Before step 7,
fix every line that says FAIL, MISSING, BAD SHAPE, 401, 403, REJECTED, DENIED, WRITABLE or
READ-ONLY-DEFAULT-OFF. SKIP is fine for a piece this project does not use. Before you ask anyone for
a new token, run the check again: a 401 is often a broken line in a settings file, not an expired
token.

## 7. First use (PM, 30 minutes)

Start with a question. In Claude Code, inside the project folder:

```
/workflow:ask What happens today when a customer cancels less than 24 hours before?
```

`workflow:ask` answers from the code and the data, and says where each part of the answer comes
from. Use it to talk a requirement through before it becomes a ticket.

Then turn a real request into a ticket. Paste the e-mail, or point at the mail thread or sheet
row:

```
/workflow:intake <paste the request, or "the latest mail from ... about ...">
```

`workflow:intake` then works through these steps:

1. It checks that it can read Jira. If it cannot, it stops and tells you what to fix.
2. It reads the whole request and keeps what the person saw apart from what they think the
   cause is.
3. It checks the code and says what the product does today, with proof.
4. It searches Jira for an open ticket about the same thing, and for a closed one that this
   request would bring back.
5. It drafts the ticket in the company format with `workflow:ticket-format`.
6. It sharpens the draft with `workflow:spec-sharpen`, which reviews it several times until it is
   ready to sign.
7. It files the ticket as a DRAFT and gives you the link.

Read the ticket. If it says what should be true and you agree, sign it by moving it to the
signed status (for example "Ready for Dev"). If not, tell Claude what is wrong and it revises the
draft.

## 8. What never happens (everyone)

- Claude never writes to production. No data fixes, no migrations, no sending messages to
  customers. The accounts from step 5 cannot, and if something needs changing, Claude tells you
  what and stops.
- Claude never merges code. Merging is a person's decision.
- Claude never signs a ticket. Moving a ticket to the signed status is a person's act, and it is
  the only thing that allows work on it to start.
- Claude never asks you for your personal cloud login to get around a read-only limit. If it
  does, say no and tell the engineer.
