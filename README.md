# Dotfiles

This repository contains my personal dotfiles for various tools and applications. It's organized to work with GNU Stow for easy deployment.

## Quick Install

For a fresh macOS installation, you can use the automated install script:

```bash
curl -fsSL https://raw.githubusercontent.com/thoreinstein/dotfiles/main/install.sh | bash
```

This will:
1. Install Homebrew
2. Clone this repository
3. Install all packages from Brewfile
4. Deploy dotfiles using GNU Stow
5. Install Tmux Plugin Manager
6. Configure Zsh shell
7. Set up Neovim with plugins

## Structure

- `nvim/`: Neovim configuration with LSP support
- `zsh/`: Zsh shell configuration
- `tmux/`: Tmux terminal multiplexer configuration
- `ghostty/`: Ghostty terminal configuration
- `git/`: Git configuration
- `markdown/`: Markdownlint configuration
- `bat/`: Bat (cat replacement) configuration
- `eza/`: Eza (ls replacement) configuration
- `ripgrep/`: Ripgrep configuration
- `fd/`: Fd (find replacement) configuration
- `bin/`: Custom scripts

## Manual Setup

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

## Shell

This setup uses **Zsh** for POSIX portability and server compatibility.

**Why Zsh over Fish:**
- POSIX-compatible (works on any server without installing Fish)
- Available by default on macOS and most Linux distros
- Better job control and scripting capabilities

**Fish-like features via plugins:**
- Autosuggestions (`zsh-autosuggestions`)
- Syntax highlighting (`zsh-syntax-highlighting`)
- Modern prompt (`starship`)

## Security Note

Sensitive information like API tokens and passwords should not be stored in dotfiles. Instead:

1. Create a `~/.tokens` file for sensitive environment variables
2. Keep this file out of version control
3. Source it from `.zshrc` using: `[ -f ~/.tokens ] && source ~/.tokens`