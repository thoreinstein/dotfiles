# Dotfiles

Personal dotfiles for macOS, managed with [Nix](https://nixos.org/), [nix-darwin](https://github.com/LnL7/nix-darwin), and [home-manager](https://github.com/nix-community/home-manager).

## Quick Install

Requires [Nix](https://nixos.org/download/) with flakes enabled.

```bash
git clone git@github.com:thoreinstein/dotfiles.git ~/src/thoreinstein/dotfiles
cd ~/src/thoreinstein/dotfiles
nix run nix-darwin/master#darwin-rebuild -- switch --flake '.#<hostname>'
```

Subsequent rebuilds:

```bash
make switch    # Applies config (auto-detects hostname)
make build     # Build without applying
make update    # Update flake inputs
make check     # Run flake checks
make fmt       # Format nix files
```

## Hosts

| Host | User | Description |
|------|------|-------------|
| `Jims-Mac-mini` | `myers` | Mac mini |
| `mac-1QFL40HG` | `jimmyers` | MacBook |

Adding a new host: add a `darwinConfigurations` entry in `flake.nix` using `mkDarwinHost`.

## What's Included

| Tool | Description |
|------|-------------|
| **Neovim** | Managed via [NixVim](https://github.com/nix-community/nixvim) — LSP, Treesitter, Telescope, conform |
| **Zsh** | Autosuggestions, syntax highlighting, cached completions |
| **Tmux** | Rose Pine theme, vim-tmux-navigator, TPM plugins |
| **Starship** | Minimal prompt with git status & cmd duration |
| **Git** | GPG signing, delta diffs, worktree aliases |
| **Ghostty** | Rose Pine theme, JetBrains Mono Nerd Font |
| **CLI Tools** | bat, eza, fd, ripgrep, fzf, atuin, zoxide, direnv |

## Structure

```
dotfiles/
├── flake.nix              # Flake entry point with mkDarwinHost helper
├── flake.lock
├── Makefile               # switch, build, check, fmt, update
├── modules/
│   ├── darwin/
│   │   ├── default.nix    # Users, fonts, nix settings
│   │   ├── homebrew.nix   # Casks managed by nix-darwin
│   │   └── system.nix     # macOS defaults (dock, keyboard, finder)
│   └── home/
│       ├── default.nix    # Home-manager entry point
│       ├── zsh.nix        # Shell config, aliases, completions
│       ├── tmux.nix       # Tmux config
│       ├── git.nix        # Git + delta
│       ├── starship.nix   # Prompt
│       ├── ghostty.nix    # Terminal
│       ├── bin.nix        # Custom scripts (ts, ghclone, git-cleanup)
│       ├── nixvim/        # Neovim config (14 modules)
│       │   ├── lsp.nix
│       │   ├── completion.nix
│       │   ├── formatting.nix
│       │   ├── treesitter.nix
│       │   └── ...
│       └── ...            # atuin, bat, eza, fd, ripgrep, etc.
├── bat/                   # Bat themes (Rose Pine)
├── bin/                   # Custom shell scripts
└── secrets/               # Secret definitions
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
| `<leader>rf` | Format buffer |
| `<leader>rt` | Toggle format on save |
| `S-h` / `S-l` | Previous/Next buffer |

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
git s           # Short status
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

### Rebuild fails

```bash
make build    # Build without switching to see errors
```

### GPG signing fails

```bash
gpgconf --kill gpg-agent && gpg-agent --daemon
```

### Tmux plugins not loading

```bash
~/.tmux/plugins/tpm/bin/install_plugins
```
