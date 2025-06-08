# Homebrew PATH setup (must be first)
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export PATH="$HOME/go/bin:$PATH"

# MyersLabs Digital Laboratory ZSH Theme
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#475569,bg=none,bold,underline"
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
export ZSH_AUTOSUGGEST_USE_ASYNC=true
export ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# Remove zsh-autocomplete - using standard completion + autosuggestions
# source /opt/homebrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
source /opt/homebrew/share/zsh-autopair/autopair.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Configure standard zsh completion for cycling (after plugins load)
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Proper keybindings for zsh-autosuggestions
bindkey '^[[C' forward-char            # Right arrow accepts suggestion
bindkey '^F' autosuggest-accept        # Ctrl+F accepts suggestion  
bindkey '^I' expand-or-complete        # Tab for normal completion
bindkey '^[[A' up-line-or-search       # Up arrow for history
bindkey '^[[B' down-line-or-search     # Down arrow for history

export PATH="$PATH:$HOME/.bin/"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

export EDITOR=nvim

bindkey -s ^f "ts\n"

# Load edit-command-line widget
autoload -z edit-command-line
zle -N edit-command-line
bindkey '^xe' edit-command-line
bindkey '^x^e' edit-command-line

alias l='ls -hAlF'
alias vim='nvim'
alias bob='claude'
alias bobc='claude -c'

eval "$(starship init zsh)"
eval "$(fzf --zsh)"
eval "$(direnv hook zsh)"

source <(kubectl completion zsh)
source <(helm completion zsh)
source <(talosctl completion zsh)
source <(ct completion zsh)
source <(cilium completion zsh)

export GPG_TTY="$(tty)"
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent
gpg-connect-agent updatestartuptty /bye > /dev/null

alias gan='git add -N'
alias gap='git add -p'
alias gis='git status -sb'
alias k='kubectl'
alias kap='kubectl apply -f'
alias kd='kubectl delete -f'
alias mcpg='npx @michaellatman/mcp-get@latest install'
alias ta='terraform apply'
alias talos='talosctl'
alias tay='terraform apply -auto-approve'
alias tc='terraform console'
alias td='terraform destroy'
alias tdr='terraform destroy -refresh=false'
alias tdy='terraform destroy -auto-approve'
alias tf='terraform fmt -recursive'
alias ti='terraform init'
alias tiu='terraform init -upgrade'
alias tp='terraform plan'
alias tv='terraform validate'

# Load tokens from secure storage
[ -f ~/.tokens ] && source ~/.tokens
[ -f ~/.config/aliasrc ] && source ~/.config/aliasrc
alias claude="/Users/myers/.claude/local/claude"
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/myers/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions
