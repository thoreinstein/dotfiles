{ pkgs, ... }:
{
  home.packages = with pkgs; [
    codespell
    dolt
    k9s
    nodejs
    opentofu
    pkg-config
    poppler-utils
    terminal-notifier
    terragrunt
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
