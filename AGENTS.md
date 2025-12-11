# Dotfiles Repository - Agent Guidelines

## Build Commands
- `make install` - Deploy all dotfiles via GNU Stow
- `make clean` - Remove all symlinks
- `make <target>` - Deploy specific config (nvim, fish, git, tmux, bat, etc.)
- `./install.sh` - Full macOS bootstrap (Homebrew, packages, dotfiles)

## Code Style
**Lua (Neovim config):** Enforced via StyLua
- 2 spaces indent, 120 char line width, Unix line endings
- Double quotes preferred, no call parentheses
- Run: `stylua nvim/.config/nvim/`

**Shell scripts:** POSIX-compatible where possible, use shellcheck

## Structure
Each tool has its own directory matching GNU Stow conventions:
- `<tool>/.config/<tool>/` for XDG configs
- `bin/.bin/` for executable scripts

## Conventions
- Never commit sensitive files (tokens, secrets, credentials)
- Test changes locally before committing
- Keep configs modular - one tool per stow package
- Use Catppuccin Mocha theme consistently across tools
