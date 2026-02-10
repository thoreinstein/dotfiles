# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Tools
alias code='opencode'
alias k='kubectl'
alias vim='nvim'
alias gap='git add -p'
alias gan='git add -N'
alias cat='bat'

# Typos
alias gits='git s'

# eza
alias l='eza -halF'
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

# ripgrep
alias rga='rg --text'
alias rgl='rg -l'
alias rgc='rg -c'
alias rgi='rg -i'
alias rgf='rg --files'

# fd
alias fda='fd --hidden'
alias fde='fd --extension'
alias fdt='fd --type'
alias fdx='fd --exec'
alias fdf='fd --follow'
alias fdd='fd --type d'
alias fdfe='fd --type f --extension'
