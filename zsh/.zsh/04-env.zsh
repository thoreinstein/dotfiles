# Build PATH with unique entries only
typeset -U path
path=(
  $HOME/.local/bin
  $HOME/.bin
  $(brew --prefix 2>/dev/null)/opt/coreutils/libexec/gnubin
  $HOME/go/bin
  $path
)

# Bun installation
export BUN_INSTALL="$HOME/.bun"
path=($BUN_INSTALL/bin $path)
path=($HOME/.docker/bin $path)
path=(/opt/homebrew/opt/postgresql@17/bin $path)

export PATH

# Environment
export EDITOR="nvim"
export K9S_CONFIG_DIR="$HOME/.config/k9s"
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"
