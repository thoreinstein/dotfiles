# Zsh Options (fish-like behavior)
setopt autocd              # cd by typing directory name
setopt correct             # spelling correction
setopt hist_ignore_all_dups # no duplicate history entries
setopt share_history       # share history between sessions
setopt extended_glob       # extended globbing
setopt interactive_comments # allow comments in interactive shell
setopt no_beep             # no beeping

# History
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

# Emacs keybindings
bindkey -e
