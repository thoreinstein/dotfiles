# Agent Notes

Global context for coding agents on this machine — how I want you to work, plus
machine-level facts. Anything project-specific belongs in that project's own AGENTS.md
or CLAUDE.md.

## Working style

- When intent or conventions are unclear, ask before proceeding — including asking for an
  existing example to follow. A question costs less than work in the wrong direction.
- Match the surrounding code: naming, idiom, comment density. Read a neighbouring file first.
- Comments explain why; the code already says what.

## Changes

**Verification loop**: `make check` → `make build` → `make switch`

Any change to `programs.pi-coding-agent.settings` (including `AGENTS.md`) requires
generating new golden files in `tests/pi/`. Run:

```bash
for h in "Jims-Mac-mini:myers" "mac-1QFL40HG:jimmyers"; do
  IFS=: read -r host user <<< "$h"
  mkdir -p "tests/pi/$host"
  for a in settings models; do
    nix eval --json ".#darwinConfigurations.$host.config.home-manager.users.$user.programs.pi-coding-agent.$a" \
      | nix shell nixpkgs#jq -c jq . > "tests/pi/$host/$a.json"
  done
done
```

Then run `make check` to confirm.

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
