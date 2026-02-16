_:
{
  imports = [
    ./cli.nix
  ];

  # Core home-manager configuration
  home.stateVersion = "23.11";

  programs.home-manager.enable = true;
}
