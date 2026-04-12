_:
{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      search_mode = "fuzzy";
      filter_mode = "directory";
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
      style = "full";
    };
  };
}
