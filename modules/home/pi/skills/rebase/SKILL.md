---
name: rebase
description: >-
  Bring the current branch up to date with trunk and resolve every conflict
  along the way, start to finish, without stopping to ask. Use when the user
  says "rebase", "rebase on main", "sync with main", "fix the rebase", "fix
  the conflicts", or a rebase has stopped on conflicts.
---

# Rebase

Get the rebase done. Resolve conflicts on your own judgment; the user wants
the result, not a play-by-play.

Never push, never `git rebase --abort`, never amend a commit
(`--amend`, `commit --fixup`, squashing). Don't rewrite or reorder the
branch's commits beyond replaying them.

## 1. Start or pick up

- `git status`. If a rebase is already stopped, continue from step 2.
- Otherwise run `git sync` (fetch, then `git rebase --autostash origin/HEAD`).
  If it finishes cleanly, skip to step 3.
- If autostash fails on intent-to-add files (`git add -N`), stop and say so.
  Don't commit or drop them yourself.

## 2. Resolve each stop

Repeat until the rebase finishes:

1. List the conflicted files: `git diff --name-only --diff-filter=U`.
2. Learn both sides before editing:
   - What this commit meant to do: `git show REBASE_HEAD`.
   - What trunk changed in those files: `git log -p ORIG_HEAD..origin/HEAD -- <file>`
     (or the merge base onward), plus any PR or ticket it names.
3. Edit each file so both intents survive. Remove every conflict marker. When
   the two really can't coexist, trunk wins on structure (renames, moved
   code, new APIs) and the commit wins on its own feature; port the commit's
   change onto trunk's shape.
4. Lock files and generated files: take trunk's version, then regenerate the
   way the repo normally does, if the commit's change needs it.
5. `git add` the files, then `GIT_EDITOR=true git rebase --continue`.
6. If the commit comes out empty because trunk already contains it, use
   `git rebase --skip`. That is the only reason to skip.

If the same conflict fails twice, or a resolution needs a decision only the
user can make (which behaviour is correct), stop and explain what you see.
Leave the rebase stopped.

## 3. Check and report

- Look for no leftover markers: `git grep -nE '^(<<<<<<<|>>>>>>>)'`.
- Run the repo's usual check if AGENTS.md, CLAUDE.md or a Makefile names one
  (`make check`, the test command). Fix breakage the resolution caused with a
  new commit. Never amend.
- Report:
  - how many commits were replayed and skipped,
  - each conflicted file and how it was resolved, one line each,
  - the check result.

  Leave pushing to the user.
