---
name: wrap-up
description: >-
  Finish a piece of work before it gets committed or handed off: bring the
  runbooks, docs and memory up to date with what changed, then report what is
  still uncommitted, unapplied or undone. Use when the user says "wrap up",
  "wrap it up", "anything left?", "anything left to do?", or "update the docs
  and runbooks".
---

# Wrap-up

Close the loop on the change just made, so nothing is left only in this
session. This runs before the commit. `compound` is the other one, after a
PR merges, and is about lessons.

Don't commit, push or switch. Edit only docs, runbooks and memory, never
code or config. If a doc needs a code change to be true, say so instead.

## 1. What changed

- `git status --short` and `git diff --stat`, plus commits not yet pushed:
  `git log --oneline @{u}..` (or `origin/HEAD..` when there's no upstream).
- Read the diffs. Note each behaviour change: a new command, alias, skill,
  setting, rule, file path, or a default that now works differently.

## 2. Runbooks and docs

- **Dotfiles:** the runbooks are `~/Documents/second_brain/reference/runbooks/rb-*.md`,
  indexed in `Runbooks.md`. Find the ones that cover each changed file
  (search them for the path, module or tool name) and update what's stale:
  steps, "Check it worked", "If it breaks", and the `file:line` references
  under "Where it lives" (line numbers move when lines are inserted above
  them). A new feature with no runbook gets a line in the closest one, or
  name the gap if none fits.
- **Other repos:** check README, AGENTS.md, CLAUDE.md and docs/ for anything
  the change made wrong.
- Change only what the diff made stale. Don't rewrite or tidy around it.

## 3. Memory

- `mem_search` for this work. `mem_save` each decision, bugfix or gotcha from
  the session that isn't saved yet, with its why. Don't duplicate.

## 4. Report

Short lists, empty ones left out:

- **Updated:** each runbook, doc or memory touched, one line each.
- **Uncommitted:** files still modified, and unpushed commits.
- **Needs applying:** dotfiles changes that need `make switch`, and anything
  that needs a restart or `/reload` after it.
- **Left undone:** follow-ups and open questions from the session.
