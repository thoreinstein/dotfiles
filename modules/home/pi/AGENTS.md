# Agent Notes

Global context for coding agents on this machine. Machine- and user-level facts only —
anything project-specific belongs in that project's own AGENTS.md or CLAUDE.md.

## Environment

- macOS, managed declaratively with nix-darwin + home-manager. Everything is declared in
  the flake — nix packages plus a small set of Homebrew casks in
  `modules/darwin/homebrew.nix` (with `cleanup = "zap"`, so anything installed by hand is
  removed on the next switch). To add a tool, add it to the flake; don't reach for
  `brew install`, `npm i -g`, or `pip install`.
- Two hosts, two usernames: `myers` (Mac mini) and `jimmyers` (work MacBook). Never
  hardcode `/Users/<name>`; use `$HOME` or the host's configured user.
- Dotfiles live in `~/src/thoreinstein/dotfiles` — a bare repo with per-branch worktrees,
  so the checkout you're in is one worktree among several.

## Tooling

- Editor is Neovim, configured through nixvim. It is fully declarative: there is no
  `lazy.nvim` and no runtime `:PlugInstall` — Neovim changes are nix expressions.
- Terminal is ghostty; multiplexer is tmux.
- Rose Pine theme, JetBrains Mono Nerd Font.
- Your own settings (`~/.pi/agent/settings.json`) are managed by this flake and symlinked
  read-only into `/nix/store`. Runtime changes you write there — `/model`, `/theme`,
  thinking level, etc. — fail silently and won't persist across a restart; to change them
  for good, edit `modules/home/pi/default.nix` or the relevant `hosts/<hostname>.nix` and
  run `make switch`.

## Git

- Identity lives in `~/.gitconfig.local`, untracked. Don't write `user.name` /
  `user.email` into a repo's own config.
- Commit signing is on. A commit that fails to sign is a configuration problem to
  report, not a reason to pass `--no-gpg-sign`.
