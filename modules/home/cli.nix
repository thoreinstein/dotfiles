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
