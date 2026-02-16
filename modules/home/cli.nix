_:
{
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
    fd = {
      enable = true;
      ignores = [
        ".git/"
        "node_modules/"
        "vendor/"
        "target/"
      ];
    };
    fzf.enable = true;
    jq.enable = true;
    ripgrep = {
      enable = true;
      arguments = [
        "--max-columns=150"
        "--max-columns-preview"
        "--hidden"
        "--smart-case"
        "--glob=!.git/"
        "--glob=!node_modules/"
      ];
    };
    zoxide.enable = true;
  };

  home.file.".config/eza/theme.yml".source = ../../eza/.config/eza/theme.yml;
}
