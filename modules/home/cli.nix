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
    bat = {
      enable = true;
      config = {
        theme = "rose-pine";
        style = "numbers,changes,header";
        italic-text = "always";
        paging = "auto";
        map-syntax = [
          "*.ino:C++"
          "*.yml:YAML"
          "*.yaml:YAML"
          "*.json:JSON"
        ];
        wrap = "auto";
      };
      themes = {
        rose-pine = {
          src = ../../bat/.config/bat/themes;
          file = "rose-pine.tmTheme";
        };
        rose-pine-moon = {
          src = ../../bat/.config/bat/themes;
          file = "rose-pine-moon.tmTheme";
        };
      };
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
