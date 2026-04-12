_:
{
  imports = [
    ./bin.nix
    ./cli.nix
    ./git.nix
    ./ghostty.nix
    ./gpg.nix
    ./markdown.nix
    ./neovim.nix
    # ./nixvim  # uncomment to switch to nixvim, remove neovim.nix above
    ./tmux.nix
    ./zsh.nix
  ];

  # Core home-manager configuration
  home.username = "myers";
  home.homeDirectory = "/Users/myers";
  home.stateVersion = "23.11";

  programs.home-manager.enable = true;
}
