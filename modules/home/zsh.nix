{ lib, ... }:
{
  programs.zsh = {
    enable = true;

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    defaultKeymap = "emacs";

    history = {
      size = 50000;
      save = 50000;
      ignoreAllDups = true;
      share = true;
      path = "$HOME/.zsh_history";
    };

    shellAliases = {
      # Directory navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";

      # Tools
      code = "opencode";
      k = "kubectl";
      gap = "git add -p";
      gan = "git add -N";
      cat = "bat";

      vim = "nvim";

      # Typos
      gits = "git s";

      # eza
      ls = "eza";
      l = "eza -la";
      ll = "eza -lg";
      la = "eza -la";
      lt = "eza --tree";
      lg = "eza -la --git";
      lh = "eza -la --header";
      ld = "eza -lD";
      lf = "eza -lf";
      lx = "eza -la --sort=extension";
      lk = "eza -la --sort=size";
      lm = "eza -la --sort=modified";
      lr = "eza -la --sort=modified --reverse";

      # ripgrep
      rga = "rg --text";
      rgl = "rg -l";
      rgc = "rg -c";
      rgi = "rg -i";
      rgf = "rg --files";

      # fd
      fda = "fd --hidden";
      fde = "fd --extension";
      fdt = "fd --type";
      fdx = "fd --exec";
      fdf = "fd --follow";
      fdd = "fd --type d";
      fdfe = "fd --type f --extension";
    };

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        # Detect and configure Homebrew for cross-platform compatibility
        if [[ -x /opt/homebrew/bin/brew ]]; then
          HOMEBREW_PREFIX="/opt/homebrew"
        elif [[ -x /usr/local/bin/brew ]]; then
          HOMEBREW_PREFIX="/usr/local"
        elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
          HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
        elif command -v brew >/dev/null 2>&1; then
          HOMEBREW_PREFIX="$(brew --prefix)"
        fi
        [[ -n "$HOMEBREW_PREFIX" ]] && eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
      '')
      ''
        # Shell options
        setopt autocd
        setopt correct
        setopt extended_glob
        setopt interactive_comments
        setopt no_beep

        # Completion setup
        fpath=(~/.docker/completions $fpath)
        zstyle ':completion:*' menu select
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        zstyle ':completion:*:descriptions' format '%B%d%b'

        # PATH
        typeset -U path
        path=(
          $HOME/.local/bin
          $HOME/.bin
          ''${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin}
          $HOME/go/bin
          $path
        )
        export BUN_INSTALL="$HOME/.bun"
        path=($BUN_INSTALL/bin $path)
        path=($HOME/.docker/bin $path)
        path=(/opt/homebrew/opt/postgresql@17/bin $path)
        export PATH

        # Environment
        # TODO: remove EDITOR once neovim.nix defaultEditor is confirmed working
        export EDITOR="nvim"
        export K9S_CONFIG_DIR="$HOME/.config/k9s"
        export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

        # GPG/SSH agent
        export GPG_TTY=$(tty)
        export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
        if ! pgrep -x gpg-agent >/dev/null 2>&1; then
          gpgconf --launch gpg-agent
          gpg-connect-agent updatestartuptty /bye > /dev/null
        fi

        # FZF defaults
        if command -v rg >/dev/null 2>&1; then
          export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
          export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        fi

        # Cargo/Rust
        if [[ -f "$HOME/.cargo/env" ]]; then
          . "$HOME/.cargo/env"
        fi

        # Dynamic tool completions
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

        # Local overrides
        [[ -f "$HOME/.zsh/local.zsh" ]] && source "$HOME/.zsh/local.zsh"
        [[ -f "$HOME/.zsh/local-aliases.zsh" ]] && source "$HOME/.zsh/local-aliases.zsh"
      ''
    ];
  };

  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ../../starship/.config/starship.toml);
  };
}
