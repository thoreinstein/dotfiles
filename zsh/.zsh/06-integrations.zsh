# Tool initializations
[[ -x $(command -v starship) ]] && eval "$(starship init zsh)"
[[ -x $(command -v atuin) ]]    && eval "$(atuin init zsh)"
[[ -x $(command -v direnv) ]]   && eval "$(direnv hook zsh)"
[[ -x $(command -v zoxide) ]]   && eval "$(zoxide init zsh --cmd cd)"
[ -s "/Users/myers/.bun/_bun" ] && source "/Users/myers/.bun/_bun"
