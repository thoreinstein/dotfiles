# Tool completions
[[ -x $(command -v cascade) ]] && eval "$(cascade completion zsh)"
[[ -x $(command -v codex) ]]   && eval "$(codex completion zsh)"
[[ -x $(command -v bd) ]]      && eval "$(bd completion zsh)"
[[ -x $(command -v rig) ]]     && eval "$(rig completion zsh)"
[[ -x $(command -v gt) ]]      && eval "$(gt completion zsh)"
[[ -x $(command -v forge) ]]   && eval "$(forge completion zsh)"

# Google Cloud SDK
[[ -f "$HOME/Downloads/google-cloud-sdk/path.zsh.inc" ]] && . "$HOME/Downloads/google-cloud-sdk/path.zsh.inc"
[[ -f "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc" ]] && . "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc"

# Bun completions
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"
