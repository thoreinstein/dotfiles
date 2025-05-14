source /opt/homebrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

export PATH="$PATH:$HOME/.bin/"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

export EDITOR=nvim

bindkey -s ^f "ts\n"

alias l='ls -hAlF'
alias vim='nvim'

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
alias ts='terraform state'
alias tv='terraform validate'
alias k='kubectl'
alias kap='kubectl apply -f'
alias kd='kubectl delete -f'

# Load tokens from secure storage
[ -f ~/.tokens ] && source ~/.tokens