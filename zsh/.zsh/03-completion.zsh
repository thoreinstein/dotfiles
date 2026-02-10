# Add Docker completions to fpath
fpath=(~/.docker/completions $fpath)

# Completion system (fish-like)
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select                    # menu selection
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'  # case-insensitive
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS} # colored completions
zstyle ':completion:*:descriptions' format '%B%d%b'   # bold descriptions
