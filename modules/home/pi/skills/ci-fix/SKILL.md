---
name: ci-fix
description: >-
  Fix every failing CI check on the current branch's PR on your own: pull the
  failed job logs, reproduce each failure locally, fix it, and make one new
  commit per fix. Use when the user says "CI is failing", "fix CI", "checks
  are red", "pre-commit failed", or "still failing".
---

# CI Fix

Get the checks green. Work through every failure without stopping to ask,
then report.

Never push, amend, rerun CI, or skip a check: no `--no-verify`, no skip or
ignore markers, no loosened lint or test config to make a failure go away.
Don't edit CI config (`.github/`, pipeline files) unless the user named it.

## 1. Find the failures

- `gh pr view --json number,url,headRefName` for the current branch. If there
  is no PR, stop and say so.
- `gh pr checks` for the failing checks.
- `gh run view <run-id> --log-failed` for each failed run. Read only the
  failed steps.
- If the PR head isn't the local `HEAD`, say so: the logs may be for an
  older commit.

## 2. Sort them

- **Fixable in the code:** a hook, formatter, linter, type check, test or
  build step that fails because of what's in the branch.
- **Not yours to fix:** runner or infra errors, auth or permission failures,
  timeouts, rate limits, a flaky test that passes locally, or a failure
  caused by the CI config itself. Don't touch these. Note each one for the
  report, with a suggestion such as a rerun.

## 3. Fix each one

For each fixable failure, one at a time:

1. Reproduce it locally with the same command CI ran (the hook, linter or
   test, from the log or the workflow file). If it can't be reproduced,
   work from the log.
2. Fix the cause. Don't silence the check.
3. Re-run the same command and confirm it passes.
4. Commit only the files for this fix, with a message naming the check:
   `fix(<check>): <what was wrong>`. One commit per fix.

If a failure is still failing after two attempts, stop working on it and
note what you see. Move on to the next one.

## 4. Check and report

- Run the repo's full check once, if AGENTS.md, CLAUDE.md or a Makefile names
  one (`make check`, the test command).
- Report one line per failure: the check, what broke, the fix and its commit
  (or why it was left alone).
- End with what's left for the user: push, and any rerun for failures that
  weren't yours to fix.
