# Dotfiles

Personal dotfiles for macOS, managed with GNU Stow.

## Quick Install

```bash
git clone git@github.com:thoreinstein/dotfiles.git ~/src/thoreinstein/dotfiles
cd ~/src/thoreinstein/dotfiles
./install.sh
```

## What's Included

| Tool | Description |
|------|-------------|
| **Neovim** | LSP, Treesitter, Telescope, Lazy.nvim |
| **Zsh** | Fish-like experience with autosuggestions & syntax highlighting |
| **Tmux** | Rose Pine theme, vim-tmux-navigator |
| **Starship** | Minimal prompt with git status & cmd duration |
| **Git** | GPG signing, worktree aliases, Diffview merge tool |
| **Ghostty** | Catppuccin Mocha theme |
| **CLI Tools** | bat, eza, fd, ripgrep, fzf, atuin, zoxide |

## Structure

```
dotfiles/
├── nvim/        # Neovim config (Lazy.nvim, LSP, Treesitter)
├── zsh/         # Zsh shell config
├── tmux/        # Tmux config
├── git/         # Git config (uses ~/.gitconfig.local for identity)
├── starship/    # Starship prompt
├── ghostty/     # Ghostty terminal
├── bat/         # Bat themes
├── eza/         # Eza theme
├── ripgrep/     # Ripgrep config
├── fd/          # Fd ignore patterns
├── bin/         # Custom scripts (ts, ghclone, git-cleanup)
└── Brewfile     # All Homebrew packages
```

## Manual Deployment

Deploy specific configs with make:

```bash
make nvim      # Deploy Neovim config
make zsh       # Deploy Zsh config
make git       # Deploy Git config
make install   # Deploy everything
make clean     # Remove all symlinks
```

## Key Bindings

### Neovim

| Key | Action |
|-----|--------|
| `<Space>` | Leader key |
| `<leader>ff` | Find files |
| `<leader>fw` | Live grep |
| `<leader>fb` | Buffers |
| `gd` | Go to definition |
| `gr` | References |
| `<leader>ca` | Code action |
| `<leader>rn` | Rename |
| `S-h` / `S-l` | Previous/Next buffer |
| `jk` or `jj` | Exit insert mode |

### Tmux

| Key | Action |
|-----|--------|
| `C-Space` | Prefix |
| `<prefix>f` | Tmux session switcher (ts) |
| `<prefix>\|` | Split vertical |
| `<prefix>-` | Split horizontal |
| `C-h/j/k/l` | Navigate panes (vim-style) |
| `Alt-1..9` | Switch windows |

## Git Workflow

Identity is stored in `~/.gitconfig.local` (not tracked):

```gitconfig
[user]
  name = Your Name
  email = your@email.com
  signingkey = 0xYOURKEYID
```

Useful aliases:

```bash
git wl          # List worktrees
git wa <branch> # Add worktree
git pr <number> # Checkout PR in worktree
git l           # Pretty log
```

## Pre-commit Hooks

This repo uses pre-commit for code quality:

```bash
pre-commit install          # Install hooks (done automatically)
pre-commit run --all-files  # Run on all files
```

Hooks include:
- Large file detection
- Private key detection
- YAML validation
- Shellcheck for shell scripts
- StyLua for Lua formatting

## Shell

Uses **Zsh** with fish-like features:

- **Autosuggestions** via zsh-autosuggestions
- **Syntax highlighting** via zsh-syntax-highlighting
- **History search** via Atuin (Ctrl+R)
- **Prompt** via Starship
- **Smart directory jumping** via zoxide (replaces `cd`)
- Machine-specific aliases: add them to `~/.zsh/local-aliases.zsh` (sourced if present)

### Directory Navigation

```bash
..              # cd ..
...             # cd ../..
....            # cd ../../..
cd proj         # Jump to most-used directory matching "proj"
cdi             # Interactive directory picker (fzf)
```

## Custom Scripts

### `ts` - Tmux Session Switcher

Fuzzy-find and switch between git repos as tmux sessions:

```bash
ts              # Interactive picker
<prefix>f       # From within tmux
```

### `ghclone` - GitHub Clone Helper

Clone repos into organized directory structure:

```bash
ghclone https://github.com/user/repo
# Clones to ~/src/user/repo
```

## Troubleshooting

### Neovim plugins not loading

```bash
nvim --headless "+Lazy! sync" +qa
```

### Tmux plugins not loading

```bash
~/.tmux/plugins/tpm/bin/install_plugins
```

### GPG signing fails

```bash
# Restart GPG agent
gpgconf --kill gpg-agent
gpgconf --launch gpg-agent
```

### Starship prompt not showing

```bash
# Verify starship is in PATH
which starship

# Reinitialize
eval "$(starship init zsh)"
```
