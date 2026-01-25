fpath=(/Users/jimmyers/.docker/completions $fpath)

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
source ~/.zsh/01-aliases.zsh
if [[ -f ~/.zsh/local-aliases.zsh ]]; then
  source ~/.zsh/local-aliases.zsh
fi

# Build PATH with unique entries only
typeset -U path
path=(
  $HOME/.local/bin
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
  gpg-connect-agent updatestartuptty /bye > /dev/null
fi

# FZF - use ripgrep if available (Atuin handles Ctrl+R history)
if command -v rg >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Integrations
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh)"
fi

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

if command -v cascade >/dev/null 2>&1; then
  eval "$(cascade completion zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh --cmd cd)"
fi

if command -v codex >/dev/null 2>&1; then
  eval "$(codex completion zsh)"
fi

if command -v bd >/dev/null 2>&1; then
  eval "$(bd completion zsh)"
fi

if command -v rig >/dev/null 2>&1; then
  eval "$(rig completion zsh)"
fi

if command -v gt >/dev/null 2>&1; then
  eval "$(gt completion zsh)"
fi

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/myers/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/myers/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/myers/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/myers/Downloads/google-cloud-sdk/completion.zsh.inc'; fi

if command -v forge >/dev/null 2>&1; then
  eval "$(forge completion zsh)"
fi

# bun completions
[ -s "/Users/jimmyers/.bun/_bun" ] && source "/Users/jimmyers/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/.docker/bin:$PATH"
