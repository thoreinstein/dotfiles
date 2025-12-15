# shellcheck shell=bash disable=SC1090,SC2034,SC2206,SC2207,SC2155,SC2296
# Zsh Options (fish-like behavior)
setopt autocd              # cd by typing directory name
setopt correct             # spelling correction
setopt hist_ignore_all_dups # no duplicate history entries
setopt share_history       # share history between sessions
setopt extended_glob       # extended globbing
setopt interactive_comments # allow comments in interactive shell
setopt no_beep             # no beeping

# History
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

# Emacs keybindings
bindkey -e

# Completion system (fish-like)
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select                    # menu selection
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'  # case-insensitive
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS} # colored completions
zstyle ':completion:*:descriptions' format '%B%d%b'   # bold descriptions

# Load Homebrew and shell plugins (cross-platform)
source ~/.zsh/00-homebrew.zsh

# Build PATH with unique entries only
typeset -U path
path=(
  $HOME/.bin
  $(brew --prefix 2>/dev/null)/opt/coreutils/libexec/gnubin
  $HOME/go/bin
  $path
)
export PATH

# Environment
export EDITOR="nvim"
export K9S_CONFIG_DIR="$HOME/.config/k9s"
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# GPG/SSH - only launch agent if not already running
export GPG_TTY=$(tty)
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
if ! pgrep -x gpg-agent >/dev/null 2>&1; then
  gpgconf --launch gpg-agent
fi

# FZF - use ripgrep if available (Atuin handles Ctrl+R history)
if command -v rg >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Aliases - tools
alias code='opencode'
alias k='kubectl'
alias vim='nvim'
alias gap='git add -p'
alias gan='git add -N'

# Aliases - eza
alias ls='eza'
alias l='eza -la'
alias ll='eza -lg'
alias la='eza -la'
alias lt='eza --tree'
alias lg='eza -la --git'
alias lh='eza -la --header'
alias ld='eza -lD'
alias lf='eza -lf'
alias lx='eza -la --sort=extension'
alias lk='eza -la --sort=size'
alias lm='eza -la --sort=modified'
alias lr='eza -la --sort=modified --reverse'

# Aliases - ripgrep
alias rga='rg --text'
alias rgl='rg -l'
alias rgc='rg -c'
alias rgi='rg -i'
alias rgf='rg --files'

# Aliases - fd
alias fda='fd --hidden'
alias fde='fd --extension'
alias fdt='fd --type'
alias fdx='fd --exec'
alias fdf='fd --follow'
alias fdd='fd --type d'
alias fdfe='fd --type f --extension'

# Integrations
eval "$(starship init zsh)"
eval "$(atuin init zsh)"
eval "$(direnv hook zsh)"
