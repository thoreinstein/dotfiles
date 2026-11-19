{ pkgs, ... }:
{
  home.packages = with pkgs; [
    codespell
    gitleaks
    nodejs
    pkg-config
    poppler-utils
    # nixpkgs f4a03c0: onig_sys wants a system oniguruma via pkg-config, which the
    # recipe doesn't provide, so the uncached darwin build fails. Drop once fixed upstream.
    (presenterm.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkg-config ];
      buildInputs = (old.buildInputs or [ ]) ++ [ oniguruma ];
    }))
    terminal-notifier
    # macOS has no `timeout`, and agents reach for it. Only this one GNU tool, so ls/date/etc.
    # stay BSD.
    (writeShellScriptBin "timeout" ''exec ${coreutils}/bin/timeout "$@"'')
    uv
    yq-go
  ];

  # presenterm on macOS reads Library/Application Support, not ~/.config (unless XDG_CONFIG_HOME is set).
  home.file."Library/Application Support/presenterm/config.yaml".source = ./presenterm.yaml;

  programs = {
    asciinema = {
      enable = true;
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
      historyWidget.command = ""; # atuin owns Ctrl-R
      tmux.enableShellIntegration = true;
    };
    jq.enable = true;
  };
}
