{ pkgs, ... }:
{
  home.packages = with pkgs; [
    codespell
    gitleaks
    nodejs
    pkg-config
    poppler-utils
    presenterm
    terminal-notifier
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
