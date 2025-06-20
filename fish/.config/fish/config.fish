if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -gx PATH /opt/homebrew/bin $PATH
set -gx PATH /Users/myers/.bin $PATH

alias vim='nvim'

# eza aliases (modern ls replacement)
alias ls='eza'
alias l='eza -la'
alias ll='eza -lg'
alias la='eza -la'
alias lt='eza --tree'
alias lg='eza -la --git'
alias lh='eza -la --header'
alias ld='eza -lD'  # directories only
alias lf='eza -lf'  # files only
alias lx='eza -la --sort=extension'
alias lk='eza -la --sort=size'
alias lt='eza -la --sort=modified'
alias lr='eza -la --sort=modified --reverse'

set -x GPG_TTY (tty)
set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent

atuin init fish | source

# Ripgrep configuration
set -gx RIPGREP_CONFIG_PATH "$HOME/.ripgreprc"

# Ripgrep aliases
alias rg='rg'  # Use config from .ripgreprc
alias rga='rg --text'  # Search all files including binary
alias rgl='rg -l'      # Only show filenames
alias rgc='rg -c'      # Show match counts
alias rgi='rg -i'      # Case-insensitive search
alias rgf='rg --files' # List files that would be searched

# fd configuration and aliases
alias fd='fd'  # Use config from .fdignore
alias fda='fd --hidden'  # Include hidden files
alias fde='fd --extension'  # Search by file extension
alias fdt='fd --type'  # Search by type (f=file, d=directory, etc)
alias fdx='fd --exec'  # Execute command on results
alias fdf='fd --follow'  # Follow symlinks
alias fdd='fd --type d'  # Find directories only
alias fdfe='fd --type f --extension'  # Find files by extension

# FZF integration with ripgrep
if command -v fzf > /dev/null
    set -gx FZF_DEFAULT_COMMAND 'rg --files --hidden --follow --glob "!.git/*"'
    set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
    
    # Advanced ripgrep + fzf content search function
    function rff
        set RG_PREFIX "rg --column --line-number --no-heading --color=always --smart-case"
        
        if test (count $argv) -gt 0
            set INITIAL_QUERY "$argv"
            # Test if the search has any results
            if eval "$RG_PREFIX -- $INITIAL_QUERY" >/dev/null 2>&1
                FZF_DEFAULT_COMMAND="$RG_PREFIX -- $INITIAL_QUERY" \
                fzf --bind "change:reload:$RG_PREFIX -- {q} || true" \
                    --ansi --disabled --query "$INITIAL_QUERY" \
                    --height=50% --layout=reverse \
                    --delimiter : \
                    --preview 'bat --color=always {1} --highlight-line {2}' \
                    --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
                    --bind 'enter:become(nvim {1} +{2})'
            else
                echo "No matches found for '$INITIAL_QUERY'"
                return 1
            end
        else
            echo '' | fzf --bind "change:reload:$RG_PREFIX -- {q} || true" \
                --ansi \
                --height=50% --layout=reverse \
                --delimiter : \
                --preview 'bat --color=always {1} --highlight-line {2}' \
                --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
                --bind 'enter:become(nvim {1} +{2})'
        end
    end
    
    # Quick file search with preview
    function ff
        set selected (fzf --preview 'bat --color=always --style=numbers {}' --preview-window=right:50%)
        if test -n "$selected"
            nvim "$selected"
        end
    end
end
