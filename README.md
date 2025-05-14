# Dotfiles

This repository contains my personal dotfiles for various tools and applications. It's organized to work with GNU Stow for easy deployment.

## Structure

- `nvim/`: Neovim configuration (NvChad)
- `zsh/`: Zsh shell configuration
- `tmux/`: Tmux terminal multiplexer configuration
- `starship/`: Starship prompt configuration
- `git/`: Git configuration

## Setup

1. Clone the repository:
   ```bash
   git clone git@github.com:thoreinstein/dotfiles.git ~/src/thoreinstein/dotfiles
   cd ~/src/thoreinstein/dotfiles
   git worktree add main
   cd main
   ```

2. Install GNU Stow:
   ```bash
   brew install stow
   ```

3. Use Stow to symlink configurations:
   ```bash
   cd ~/src/thoreinstein/dotfiles/main
   stow -t ~ zsh tmux git
   stow -t ~/.config starship
   stow -t ~ nvim
   ```

## Security Note

Sensitive information like API tokens and passwords should not be stored in dotfiles. Instead:

1. Create a `~/.tokens` file for sensitive environment variables
2. Keep this file out of version control
3. Source it from `.zshrc` using: `[ -f ~/.tokens ] && source ~/.tokens`