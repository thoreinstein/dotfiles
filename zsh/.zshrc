# shellcheck shell=bash disable=SC1090,SC2034,SC2206,SC2207,SC2155,SC2296

# Define configuration directory
ZSH_CONFIG="$HOME/.zsh"

# Load Homebrew first
if [[ -f "$ZSH_CONFIG/00-homebrew.zsh" ]]; then
  source "$ZSH_CONFIG/00-homebrew.zsh"
fi

# Load all other modular configs
for config_file in "$ZSH_CONFIG"/[0-9][0-9]-*.zsh; do
  # Skip 00-homebrew as it's already loaded
  [[ "$config_file" == *00-homebrew.zsh ]] && continue
  source "$config_file"
done

# Load local overrides if they exist
if [[ -f "$ZSH_CONFIG/local.zsh" ]]; then
  source "$ZSH_CONFIG/local.zsh"
elif [[ -f "$ZSH_CONFIG/local-aliases.zsh" ]]; then
  # Compatibility for your existing local-aliases.zsh
  source "$ZSH_CONFIG/local-aliases.zsh"
fi
