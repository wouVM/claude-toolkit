EXAMPLE CASE: invented to show the format. Not a real case.

State of the system when asked: a signed webhook receiver for that provider shipped under a closed
ticket two weeks earlier (signature check, dedup on delivery id, guest message on the confirmed
transition). The one part left open in that ticket's description is a CRM sync, blocked on an answer
from the provider.

A working run:
- searches the tracker for the CAPABILITY (webhook, status update) including closed tickets, and the
  code, BEFORE proposing anything;
- leads with "Yes, it already ships", cites the closed ticket key and the receiver's file:line, each
  with the time it was checked;
- names the open part (CRM sync) with its blocker and who owns the answer;
- edits nothing, files nothing, and ends by offering a next step.

Counts as a miss: any design or build plan for a webhook receiver, or an answer that does not name
the closed ticket.
