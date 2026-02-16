{ pkgs, ... }:
{
  home.packages = with pkgs; [
    cloc
    coreutils
    osv-scanner
    terminal-notifier
    tldr
    tree
    wget
    yq-go
  ];

  programs = {
    atuin = {
      enable = true;
      settings = {
        search_mode = "fuzzy";
        filter_mode = "global";
        enter_accept = false;
        sync = {
          records = true;
        };
        stats = {
          common_subcommands = [
            "apt"
            "cargo"
            "composer"
            "dnf"
            "docker"
            "git"
            "go"
            "forge"
            "ip"
            "jj"
            "kubectl"
            "nix"
            "nmcli"
            "npm"
            "pecl"
            "pnpm"
            "podman"
            "port"
            "systemctl"
            "tmux"
            "yarn"
          ];
        };
      };
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
    eza.enable = true;
    fd.enable = true;
    fzf.enable = true;
    jq.enable = true;
    ripgrep.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    zoxide = {
      enable = true;
      options = [ "--cmd" "cd" ];
    };
  };

  home.file = {
    ".config/eza/theme.yml".source = ../../eza/.config/eza/theme.yml;
    ".fdignore".source = ../../fd/.fdignore;
    ".ripgreprc".source = ../../ripgrep/.ripgreprc;
  };
}
