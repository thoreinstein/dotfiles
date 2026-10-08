---
name: pr-review
description: >-
  Review a GitHub pull request locally. Use when the user asks to review a PR,
  review a colleague's changes, look at a pull request, or give review feedback
  on code that is not their own working-tree changes.
---

# PR Review

Review a GitHub pull request using `gh` and local git tooling.

## Workflow

1. **Fetch the PR.** Run `gh pr checkout <number-or-URL>` (or
   `gh pr diff <n> > /tmp/pr.diff` if the user only wants a diff read, not a
   checkout). If the user gave no number, run `gh pr list` first and ask which.

2. **Orient.** Read the PR description with `gh pr view <n>`. Identify the base
   branch (`gh pr view <n> --json baseRefName`).

3. **Read the changes.** Use `git diff <base>...HEAD` plus the quickfix
   workflow: `git diff --name-status <base>...HEAD` to list files, then read
   each file in full around the changed hunks. Read enough surrounding code to
   judge the change in context, not just the diff lines.

4. **Verify what can be verified.** Run the project's build, tests, and linters
   if they are quick (< ~2 min). Report failures as findings.

5. **Report.** Write findings grouped by severity:
   - **Blocking** — bugs, broken edge cases, security issues, data loss risks.
   - **Should fix** — design problems, missing tests, misleading names.
   - **Nits** — style, minor polish. Keep these short.

   For each finding: file:line, what is wrong, why, and a concrete suggestion.
   Note what you checked and found fine, so the author knows the coverage.

6. **Posting.** Offer to post the review with
   `gh pr review <n> --comment --body-file <file>` (approve/request-changes
   variants) or leave it for the user to paste into the UI. Ask before posting.

## Notes

- Review the code as it is on the branch, not the diff in isolation — read the
  touched functions in full.
- Do not modify the PR branch's files; this is a read-only review.
- If tests are slow or flaky, say so rather than skipping silently.
