---
name: plan-review
description: >-
  Check an existing plan note in the vault against the current code and fix
  what has gone stale: moved files, wrong assumptions, vague steps, missing
  risks. Use when the user says "review the plan", "is the plan still right",
  "check the plan before I start", or picks a ticket back up after a gap.
---

# Plan Review

Review a plan that already exists. Don't write a new one; if there's no
plan, say so and stop.

Read anything in the repo. Write nothing in the repo: no code, no files, no
commits. Don't run builds or tests, and don't touch the ticket. The only
thing this skill changes is the plan note, and only the edits the user
accepts.

## 1. Find the plan

- If `WB_NOTE` is set, the plan is `<KEY>-plan.md` in the same vault folder.
- Otherwise `obsidian_search_notes` for `<KEY>-plan` or ask which plan.
- Read it with `obsidian_read_note`. Read the ticket note too if there is
  one: its Log may record decisions made after the plan was written.

## 2. Check it against the code

For every file, module, resource or command the plan names, open the
current version and check the claim. Look for:

- **Stale references.** Paths, names or line numbers that moved or no
  longer exist.
- **Wrong assumptions.** The plan says the code does X; it does Y.
- **Vague steps.** A step that doesn't say which file or what change.
- **Missing risks.** Irreversible or shared changes (state moves, IAM,
  DNS, shared modules, CI) with no check before them.
- **Order.** Steps that depend on a later step, or could be done earlier.
- **Already done.** Steps the code or Log shows are finished.

Cite file:line for each finding. A plan that holds up is a fine result; say
so and stop.

## 3. Walk the findings

Present one finding at a time with the proposed edit to the plan text, then
wait. Apply only the ones the user accepts.

## 4. Update the note

Edit the plan in place with `obsidian_replace_section`, keeping its
structure and voice: refine, don't rewrite. Never create a second plan note.
If `WB_NOTE` is set, append one dated Log line saying the plan was reviewed
and what changed.
