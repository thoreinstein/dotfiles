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

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
