{ lib, ... }:
{
  programs.zsh = {
    enable = true;

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    defaultKeymap = "emacs";

    completionInit = ''
      autoload -Uz compinit
      if [[ -f "$HOME/.cache/zsh/zcompdump" ]] && [[ $(date +'%j') == $(stat -f '%Sm' -t '%j' "$HOME/.cache/zsh/zcompdump" 2>/dev/null) ]]; then
        compinit -C -d "$HOME/.cache/zsh/zcompdump"
      else
        mkdir -p "$HOME/.cache/zsh"
        compinit -d "$HOME/.cache/zsh/zcompdump"
      fi
    '';

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

      tf = "tofu";
      tg = "terragrunt";
    };

    initContent = lib.mkMerge [
      (lib.mkAfter ''
        eval "$(zoxide init zsh --cmd cd)"
      '')
      (lib.mkBefore ''
        # nix-darwin manages Homebrew PATH via /etc/zshenv
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
          $HOME/go/bin
          $path
        )
        export BUN_INSTALL="$HOME/.bun"
        path=($BUN_INSTALL/bin $path)
        path=($HOME/.docker/bin $path)
        path=(/opt/homebrew/opt/postgresql@17/bin $path)
        export PATH

        # Environment
        export K9S_CONFIG_DIR="$HOME/.config/k9s"

        # FZF defaults
        if command -v rg >/dev/null 2>&1; then
          export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
          export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        fi

        # Cargo/Rust
        if [[ -f "$HOME/.cargo/env" ]]; then
          . "$HOME/.cargo/env"
        fi

        # Dynamic tool completions (cached to avoid slow eval on every shell)
        _cache_completion() {
          local cmd=$1 cache="$HOME/.cache/zsh-completions/_''${cmd}"
          if [[ ! -f "$cache" ]] || [[ $(command -v "$cmd") -nt "$cache" ]]; then
            mkdir -p "$HOME/.cache/zsh-completions"
            "$cmd" completion zsh > "$cache" 2>/dev/null
          fi
          [[ -f "$cache" ]] && source "$cache"
        }
        for cmd in cascade codex rig gt forge; do
          [[ -x $(command -v "$cmd") ]] && _cache_completion "$cmd"
        done
        unfunction _cache_completion

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
}
