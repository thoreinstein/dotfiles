{ pkgs, ... }:
{
  programs.atuin = {
    enable = true;
    # Temporary: atuin 18.24.4 fails its own e2e_ai_sessions tests on darwin
    # (hydra's aarch64-darwin build is red, so there is no cached stock build
    # either). Skipping the check phase changes the derivation hash, which
    # forces a source build on every atuin bump, so drop this override as soon
    # as hydra is green again:
    #   nix path-info --store https://cache.nixos.org \
    #     "$(nix eval --raw .#darwinConfigurations.mac-1QFL40HG.pkgs.atuin.outPath)"
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
