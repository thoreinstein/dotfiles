---
name: compound
description: >-
  Retrospective after a piece of work lands: compare what was asked, what was
  planned and what shipped, then turn the lessons into traps, patterns and
  decisions in engram and the vault. Use when the user says "compound",
  "compound this", "retro this ticket", "what did we learn", or after they say
  a PR merged and the work is done.
---

# Compound

Turn finished work into knowledge the next session can use. The output is
memory and vault notes. Never edit source, config, tests, AGENTS.md or
CLAUDE.md here. If a lesson belongs in one of those, say so and stop there.

## 1. Gather

Read only. Use whatever exists, skip what doesn't, and don't ask for things
you can look up.

- **Ticket note.** If `WB_NOTE` is set, read it: Description is the ask, Log
  is what happened, and it holds the PR link.
- **Plan.** `obsidian_rag_query` for the ticket key or topic under
  `working/<project>/`. A plan note is the strategy to compare against.
- **What shipped.** The commits for this work: `git log --oneline` and
  `git diff --stat` over the range. If the PR is merged, use the merge or
  squash commit on the default branch. If the range is unclear, ask for it.
- **Memory.** `mem_search` the ticket key and project for decisions and
  bugfixes saved while the work was in progress.
- **Manual commands.** What I ran by hand in the ticket's worktree over the
  work's date range: workarounds, retries, failed commands the agent never
  saw. `--cwd` is an exact match, so filter `{directory}` with `grep` for
  subdirectories.
  ```bash
  atuin search --filter-mode global --include-duplicates --author '$all-user' \
    --after "YYYY-MM-DD" --format '{time}|{exit}|{directory}|{command}'
  ```

## 2. Compare

Walk the layers in order and note each gap with its evidence:

1. **Ask vs plan.** What did the plan miss, add or misread?
2. **Plan vs shipped.** Which steps changed, got dropped or were added? Why?
3. **After the first PR.** Review rounds, fix-up commits, reverts. What did
   each one catch that earlier steps should have?
4. **Workflow.** Where did time go: wrong assumptions, retries, waiting,
   missing context?

## 3. Draft

From the gaps, draft candidates in three kinds:

- **Trap.** Something that bit us, a gotcha, or harder than it looked.
- **Pattern.** A reusable approach this work established or confirmed.
- **Decision.** A choice that binds future work, with its reason.

Each candidate gets a one-line claim, its evidence (commit, file:line, Log
line) and a scope: this project only, or general. Zero of a kind is fine.
Don't invent lessons to fill the categories, and don't restate what is
already in engram or the vault. Search before drafting a candidate.

Show the list, ask what to add, cut or reword, and wait.

## 4. Record

For each candidate the user keeps:

- **Engram, always.** `mem_save` with the matching type
  (decision, pattern, discovery, bugfix), the project, and the evidence.
- **Vault, only when general.** Write it to `Engineering/Traps`,
  `Engineering/Patterns` or `Engineering/Decisions` using the templates in
  `reference/VAULT_CONVENTIONS.md`. Update an existing note instead of
  creating a near-duplicate. Mark synthesized claims `^[inferred]`, add the
  `## Links` section, and link the note from the matching MOC.
- **Ticket note.** If `WB_NOTE` is set, append one dated Log line naming
  what was recorded.

Finish with a short list of what went where. If a lesson would change how
agents behave (AGENTS.md, CLAUDE.md, a skill), propose the exact edit as text
and leave it for the user.
