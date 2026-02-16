_:
{
  imports = [
    ./bin.nix
    ./cli.nix
    ./git.nix
    ./ghostty.nix
    ./neovim.nix
    ./tmux.nix
    ./zsh.nix
  ];

  # Core home-manager configuration
  home.stateVersion = "23.11";

  programs.home-manager.enable = true;
}
