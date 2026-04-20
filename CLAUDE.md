# Dotfiles — Agent Notes

Personal macOS dotfiles: **nix-darwin + home-manager**, flake-based. See `README.md` for user-facing install, keybinds, and troubleshooting — this file is orientation for agents.

## Commands

Run from repo root. Hostname auto-detected via `scutil --get LocalHostName`.

```bash
make check    # nix flake check — run this before switch
make build    # darwin-rebuild build (no apply) — use to surface errors
make switch   # sudo darwin-rebuild switch — applies config
make fmt      # nix fmt (nixpkgs-fmt)
make update   # nix flake update
```

Verification loop for any change: `make check` → `make build` → `make switch`.

## Architecture

- `flake.nix` — single entry point. `mkDarwinHost` helper builds each `darwinConfigurations.<host>` entry; two hosts today (`Jims-Mac-mini` / user `myers`, `mac-1QFL40HG` / user `jimmyers`), both `aarch64-darwin`.
- `modules/darwin/` — shared system config (users, fonts, nix settings, `homebrew.nix`, macOS defaults in `system.nix`).
- `modules/home/` — shared home-manager config (zsh, tmux, git, starship, ghostty, CLI tools, `bin.nix`).
- `modules/home/nixvim/` — Neovim config split across ~15 submodules (lsp, completion, formatting, treesitter, keymaps, ui, …). Add Neovim features here, not in a monolith.
- `hosts/<hostname>.nix` — per-host home-manager overrides. Currently near-empty; this is the intended extension point for host-specific tweaks.
- `lib/` — placeholder for helper functions (empty today).
- `bin/` — custom scripts (`ts`, `ghclone`, `git-cleanup`) wired in via `modules/home/bin.nix`.
- `secrets/` — agenix skeleton; **not yet wired**. Don't assume secrets are available.

## Conventions & Gotchas

- **Formatter is `nixpkgs-fmt`** (set in `flake.nix` `formatter`). Don't swap for alejandra/nixfmt.
- **Pre-commit hooks** run via `nix flake check`: `nixpkgs-fmt`, `statix`, `deadnix`. CI (`.github/workflows/check.yml`) runs the same on PR to `main`/`nix`.
- **direnv**: `.envrc` uses `use flake` — entering the repo loads the devShell (codex, deadnix, nixpkgs-fmt, prettier, statix).
- **Two usernames**: `myers` on Mac mini, `jimmyers` on MacBook. Any path like `/Users/<user>` must respect the active host.
- **Git identity** lives in `~/.gitconfig.local` (untracked); GPG signing is enabled in `git.nix`.
- **Indent**: 2 spaces everywhere (`.editorconfig`). Lua uses `stylua.toml` (120-char, double quotes, spaces).

## Most-touched files

`flake.nix` · `modules/home/default.nix` · `modules/home/<tool>.nix` · `modules/home/nixvim/*.nix` · `hosts/<hostname>.nix`
