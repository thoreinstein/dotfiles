# GPG/TTY
export GPG_TTY=$(tty)

# SSH agent via GPG
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
if ! pgrep -x gpg-agent >/dev/null 2>&1; then
  gpgconf --launch gpg-agent
  gpg-connect-agent updatestartuptty /bye > /dev/null
fi

# FZF - use ripgrep if available
if command -v rg >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Cargo/Rust
if [[ -f "$HOME/.cargo/env" ]]; then
  . "$HOME/.cargo/env"
fi
