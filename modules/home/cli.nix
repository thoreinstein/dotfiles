{ pkgs, ... }:
{
  home.packages = with pkgs; [
    codespell
    nodejs
    pkg-config
    terminal-notifier
    yq-go
  ];

  programs = {
    asciinema = {
      enable = true;
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
      tmux.enableShellIntegration = true;
    };
    jq.enable = true;
  };
}
