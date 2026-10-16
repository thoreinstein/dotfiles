# Agent Notes

Global context for coding agents on this machine — how I want you to work, plus
machine-level facts. Anything project-specific belongs in that project's own AGENTS.md
or CLAUDE.md.

## Working style

- When intent or conventions are unclear, ask before proceeding — including asking for an
  existing example to follow. A question costs less than work in the wrong direction.
- Match the surrounding code: naming, idiom, comment density. Read a neighbouring file first.
- Comments explain why; the code already says what.
- When I ask for suggestions or a review, don't edit anything. Suggestions are text; edits
  happen only when I say which ones to apply.
- When working through a list (plan steps, review findings, errors), take one item at a time
  and wait for my confirmation before the next. Don't batch fixes or clean up adjacent things.
- Don't edit shared or root files (`root.hcl`, base modules, CI config, anything other stacks
  import) unless the task names them. Stop and tell me instead.
- After two failed fix attempts on the same problem, stop and explain what you think is
  happening. Don't keep trying variations.
- Before removing code whose purpose isn't obvious, check `git log -L` or blame for why it's
  there.

## Changes

**Verification loop**: `make check` → `make build` → `make switch`

Any change to `programs.pi-coding-agent.settings` (including `AGENTS.md`) requires
generating new golden files in `tests/pi/`. Run `make golden`, review the diff, then
run `make check` to confirm.

## Memory

Engram is the memory shared with Claude Code. Save decisions, bugfixes and discoveries with
`mem_save` as they happen, and write a session summary before finishing. Before asking me about
prior work, conventions or past decisions, search engram (`mem_search`), then the Obsidian vault at
`~/Documents/second_brain` if its tools are available. The vault's `engram/` folder is a
read-only mirror of engram; never edit it. Layout is in `reference/VAULT_CONVENTIONS.md`.

## Workbench tickets

`wb start` launches pi with `WB_TICKET` (ticket ID) and, when a vault is configured, `WB_NOTE`
(path to that ticket's working note in the vault). If `WB_NOTE` is set:

- Read the note at the start of a session.
- Keep `## Log` current: append a dated line (one or two sentences) when a decision is made,
  something non-obvious is found, a milestone is reached, or work stops with something unfinished.
  Include the PR link once one exists.
- Leave Summary, Description and Notes alone — they come from Jira.
- Engram stays canonical for decisions (`mem_save`). The note is the ticket's running record.

## No

- Don't discard uncommitted changes: no `checkout -- <file>`, `restore`, `reset --hard`,
  `stash drop`/`clear`, or `clean`. If they're in the way, ask me. Losing my working tree is
  the one mistake that can't be undone.
- Don't write Python. Use bash + jq; TypeScript for pi extensions.
- Don't amend commits. Fix-ups go in a new commit.
- Don't push unless I say to in this conversation. Approval to commit isn't approval to push.

## Commits

Split work into small atomic commits, one logical change each. Decide the split yourself;
don't wait for me to stage anything.
- Don’t install tools with `brew`, `npm -g`, or `pip` — add them to the flake instead.
- Don’t edit `tests/pi/*` by hand — regenerate them when settings change.
- Don’t write git identity (`user.name`/`user.email`) to repo config — it lives in `~/.gitconfig.local`.

## Output

- Lead with the outcome — the first sentence says what happened or what you found.
- Stay quiet between tool calls. Speak up for findings, changes of direction, and blockers,
  not to narrate routine steps.
- Plain text, no emojis.

## Environment

- macOS, managed declaratively with nix-darwin + home-manager. Everything declared in flake:
  nix packages + Homebrew casks (`modules/darwin/homebrew.nix`, `cleanup = "zap"`).
- Two hosts: `Jims-Mac-mini` (user `myers`) and `mac-1QFL40HG` (user `jimmyers`).
  Use `$HOME` or host-configured user — never hardcode `/Users/<name>`.
- Dotfiles repo at `~/src/thoreinstein/dotfiles`: bare git repo with per-branch worktrees.

## Tooling

- Editor: Neovim via nixvim (fully declarative — no lazy.nvim, no runtime installs).
- Terminal: ghostty; multiplexer: tmux.
- Theme: Rose Pine; font: JetBrains Mono Nerd Font.
- pi settings live in flake (`modules/home/pi/default.nix`, `hosts/*.nix`) and are symlinked
  read-only to `/nix/store`. Runtime edits to `~/.pi/agent/settings.json` fail silently
  and don’t persist — use the flake instead.

## Git

- Identity lives in `~/.gitconfig.local`, untracked. Don't write `user.name` /
  `user.email` into a repo's own config.
- Commit signing is on. A commit that fails to sign is a configuration problem to
  report, not a reason to pass `--no-gpg-sign`.

## Finding things

If you can't locate a file or don't know where something lives, ask me. Do not
search the repository to find out. A question costs one turn. A search costs
thousands of tokens and usually finds the wrong thing.

## CodeGraph

In a repo with a `.codegraph/` directory at its root, use the codegraph MCP server's
`codegraph_explore` tool before grep, find, or reading files. One call returns the relevant
symbols' current source plus the call paths between them, including dynamic-dispatch hops
grep can't follow. If the MCP tool isn't available, `codegraph explore "<symbols or question>"`
in the shell prints the same output.

No `.codegraph/` directory means skip CodeGraph. Don't run `codegraph init`; indexing is my
decision.
