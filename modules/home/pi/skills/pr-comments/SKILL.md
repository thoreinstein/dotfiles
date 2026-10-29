---
name: pr-comments
description: >-
  Work through the review comments on the current branch's PR: fetch every
  open comment, triage each one against the code, summarize for me and wait,
  then fix the ones we agree on and reply on the PR. Use when the user says
  "address the PR comments", "handle the review", "triage the feedback",
  "respond to the reviewers", or "what did they say on my PR".
---

# PR Comments

Turn review feedback into fixes and replies. Stop once, after triage, for me
to agree on the plan. After that, work without stopping until the push
question.

Never push without asking, amend, force-push, or resolve a thread you didn't
fix. Don't edit CI config (`.github/`, pipeline files) unless a comment asks
for it and I agreed.

## 1. Fetch the comments

- `gh pr view --json number,url,headRefName,headRefOid,baseRefName` for the
  current branch. If there is no PR, stop and say so. If `headRefOid` isn't
  the local `HEAD`, say so: comments may be about code that has changed.
- Review threads, with resolved state, which `gh pr view` doesn't give you:

  ```bash
  gh api graphql -F owner='{owner}' -F repo='{repo}' -F n=<number> -f query='
    query($owner:String!,$repo:String!,$n:Int!){
      repository(owner:$owner,name:$repo){ pullRequest(number:$n){
        reviewThreads(first:100){ nodes{
          id isResolved isOutdated path line
          comments(first:50){ nodes{ databaseId author{login} body url } }
        } }
      } } }'
  ```

  Keep the threads that aren't resolved. Keep outdated ones too, but mark them:
  the code they point at may have moved.
- Review summaries: `gh pr view <n> --json reviews`. Keep the non-empty bodies.
- Conversation comments: `gh pr view <n> --json comments`.
- Skip my own comments unless they're a question to the author. Flag
  comments from bots (logins ending in `[bot]`, Copilot, CodeRabbit) as
  `bot`. Triage them like the rest.

## 2. Triage

For each comment, read the code it points at (the whole function, not just
the line) and decide:

- **Fix:** the comment is right and the change belongs in this PR.
- **Push back:** the comment is wrong, already handled, out of scope, or a
  matter of taste that goes against the repo's conventions. Give the evidence:
  file:line, a test, a doc.
- **Question:** the comment asks something, or is too vague to act on. Draft
  an answer or a clarifying question.
- **No action:** praise, an FYI, or already fixed by a later commit (name
  the commit).

Don't agree just because a reviewer said it. Check the claim against the code.

## 3. Summarize and wait

Print one numbered list, grouped by verdict, with Fix first. For each item:

- `#N` · author (`bot` if it is one) · `path:line` · comment URL
- the comment in one line
- the verdict and why, in one or two lines; for Fix, the change you plan

End with the counts, then stop. Ask which to fix and whether any verdict
should change. Don't edit anything until I answer. My answer approves the
commits in step 4, and nothing beyond them.

## 4. Fix the agreed ones

One at a time:

1. Make the change. If a test can show the problem, write it first.
2. Run the checks the repo names (AGENTS.md, CLAUDE.md, Makefile) for the
   files you touched, and confirm they pass.
3. Commit only the files for this fix. Follow the repo's commit convention:
   read `git log --oneline` first, and in ForgeCloud repos use the Jira key as
   the subject prefix (`FRAAS-NNNNN <what changed>`). One commit per comment;
   comments that ask for the same change share one commit.
4. Note the short SHA against the comment.

If a fix needs more than the comment asked for, or turns out wrong after two
tries, stop working on it. Move it to Question with what you found.

## 5. Push, then reply

Ask: "Push and post replies?" Show the commits and the drafted replies.

- **No:** print the drafted replies and stop.
- **Yes:** `git push` (never `--force`), then post:
  - Review thread reply, using the first comment's `databaseId`:
    `gh api repos/{owner}/{repo}/pulls/<n>/comments/<databaseId>/replies -f body='…'`
  - Conversation or review-summary comment: `gh pr comment <n> --body '…'`, starting
    with `> ` and a quote of the line you're answering.
- Resolve only the threads you fixed:
  `gh api graphql -f query='mutation($id:ID!){resolveReviewThread(input:{threadId:$id}){thread{isResolved}}}' -F id=<thread id>`.
  Leave push-back and question threads open for the reviewer.

Replies are short and plain. No thanks, no "great catch".
- Fix: `Fixed in <sha>: <what changed>.`
- Push back: the reason and the evidence, in two or three sentences.
- Question: the answer, or the clarifying question.
- No action: reply only if the reviewer asked something. Otherwise leave it.

## 6. Report

One line per comment: `#N`, verdict, commit or reply link. End with what's
left for me: threads still open, and questions waiting on reviewers.
