{ pkgs, ... }:
{
  home.packages = with pkgs; [
    codespell
    coreutils
    nodejs
    terminal-notifier
    tree
    wget
    yq-go
  ];

  programs = {
    asciinema = {
      enable = true;
    };
    dircolors = {
      enable = true;
      enableZshIntegration = true;
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
      tmux.enableShellIntegration = true;
    };
    jq.enable = true;
  };

  home.file = { };
}
