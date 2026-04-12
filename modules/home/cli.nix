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
    eza = {
      colors = "auto";
      enable = true;
      enableZshIntegration = true;
      git = true;
      icons = "auto";
    };
    fd.enable = true;
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
    ".config/eza/theme.yml".source = ../../eza/.config/eza/theme.yml;
    ".fdignore".source = ../../fd/.fdignore;
    ".ripgreprc".source = ../../ripgrep/.ripgreprc;
  };
}
