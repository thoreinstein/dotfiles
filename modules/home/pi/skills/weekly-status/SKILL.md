---
name: weekly-status
description: >-
  Draft my reply to the Friday async Weekly Status Meeting thread in Slack: what I
  accomplished this week, what I plan for next week, epic statuses, and blockers,
  built from my pi session logs, engram memories, and Obsidian vault notes. Use
  whenever I ask for my weekly status, weekly update, Friday update, status
  report, "what did I do this week", or paste the manager's "Happy Friday!
  Let's do our Weekly Status Meeting Async" message, including for a past week
  ("last week", "week of Oct 5").
---

# Weekly status

The reply goes into a Slack thread my manager starts every Friday:

> Please share what you accomplished this week, what you're planning to
> accomplish next week, and the status of each of your epics (on track,
> off-track, concerned, or closed) in the thread. Include any blockers you may
> have or help you may need.

Readers are my manager and teammates. They want outcomes on team work, in a
minute of reading, not a log of what my agents did.

## 1. Pick the week

Default: Monday of the current week through today. "Last week" means the
previous Monday through Friday. Convert any other wording to dates and say which
range you used at the top of your answer.

## 2. Collect the raw material

Run the collector. It is read-only and prints one markdown digest:

```bash
~/.pi/agent/skills/weekly-status/scripts/week-sources.sh --start YYYY-MM-DD --end YYYY-MM-DD
```

It has three sections:

- **pi sessions** — one entry per session: day, working directory, ticket key
  taken from the directory name (e.g. `FRAAS-36446`, `INC-3804`), my first
  prompts, and pi's last reply.
- **engram observations** — every memory saved that week, grouped by project.
- **vault notes** — paths of that week's daily notes and of the `working/`
  project notes modified that week.

Then read, in this order of trust:

1. **Daily notes** (`Daily/YYYY/MM/YYYY-MM-DD.md`). They are already distilled
   per project, with decisions. Start here; they cover most of the week.
2. **Engram observations** for detail and exact names, and for anything the
   daily notes missed.
3. **Work project notes** in `working/` (ticket notes, incident notes, plans).
   They show where a ticket stands and what is left to do.
4. **pi sessions** to fill gaps: a session with a ticket key but no engram
   memory is still work that happened.

Reading vault files directly is fine. If the collector fails on engram, use
`mem_search` with the week's ticket keys and project names instead. Jira and
Glean are optional extras: use them only to check a ticket's title or state, not
to find more work.

## 3. Keep only work

The update is for my work team. Work means:

- repos under `~/src/forgecloud/` and their engram projects (e.g.
  `tf-env-saas-v2`, `saas`, `tf-env-*`, `tf-gcp-org-*`, `fraas`)
- tickets and incidents: `FRAAS-*`, `INC-*`, other Jira keys
- vault folders `working/fraas`, `working/inc`, `working/alert`,
  `working/fedramp`, `working/idx_team`, `working/infrastructure`,
  `working/tf-env-saas`

Personal, so leave it out: `~/src/thoreinstein/*` (dotfiles, workbench, plugins),
`~/src/personal*`, finances, the vault itself, agent and editor setup. Sessions in
`~` with no ticket: judge by content. Keep track of what you drop; it is listed
after the draft.

## 4. Write the reply

Use Slack formatting (`*bold*` with single asterisks, `•` bullets, `_italic_`).
Exactly this shape:

```
*Accomplished this week*
• ...

*Next week*
• ...

*Epics*
• _fill in_

*Blockers / help needed*
• None
```

**Accomplished.** One bullet per workstream, ticket or incident, 3–7 bullets
total. Lead with the outcome, then the key detail; put the ticket key first so
people can find it:
`• FRAAS-36446: finished discovery for the fr-validation state migration and wrote the migration plan; agreed to do it before FRAAS-36445 as the rehearsal.`
Not: "Ran terragrunt plan in several directories and reviewed output."
On-call and incidents count; say what happened and the result
(`• INC-3804: traced the GSM Pub/Sub alert to Google incident DYTVVTL and restored am with per-environment restarts.`).
Leave out agent mechanics (which model, skills, tool fights) and commit-level detail.

**Next week.** Infer from open threads: "next steps" in engram summaries,
unfinished phases in plans, tickets still in progress, follow-ups promised in
Jira comments. Only list what the sources support. These are guesses about my
intent, so they get checked below.

**Epics.** Leave as `_fill in_`. I set epic status myself.

**Blockers.** Only real ones from the sources: waiting on another team, access I
don't have, a decision someone else owes. Otherwise `None`.

## 5. After the draft

Below the reply, outside it, add two short lists for me only:

- **Dropped as personal:** one line per item (e.g. "dotfiles: gcloud moved to nix").
- **Check these:** next-week items you inferred and any accomplishment you were
  unsure about, each with its source.

Then stop. Don't post anywhere; I paste the reply into Slack myself.
