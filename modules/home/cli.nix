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
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
      silent = true;
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
      tmux.enableShellIntegration = true;
    };
    jq.enable = true;
    ripgrep.enable = true;
    zoxide = {
      enable = true;
      options = [
        "--cmd"
        "cd"
      ];
    };
  };

  home.file = {
    ".ripgreprc".source = ../../ripgrep/.ripgreprc;
  };
}
