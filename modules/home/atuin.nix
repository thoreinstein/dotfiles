{ pkgs, ... }:
{
  programs.atuin = {
    enable = true;
    # Skip the check phase: atuin's e2e_capture tests are PTY timing tests that
    # flake in the nix sandbox (e.g. filtered_commands_leave_no_captured_output),
    # and the binary cache lags new releases, so a flaky test means a wasted
    # ~30min source build.
    package = pkgs.atuin.overrideAttrs (_: { doCheck = false; });
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
