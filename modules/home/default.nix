_:
{
  imports = [
    ./atuin.nix
    ./bat.nix
    ./bin.nix
    ./cli.nix
    ./direnv.nix
    ./eza.nix
    ./fd.nix
    ./git.nix
    ./ghostty.nix
    ./gpg.nix
    ./markdown.nix
    ./nixvim
    ./ripgrep.nix
    ./tmux.nix
    ./zoxide.nix
    ./zsh.nix
  ];

  # Core home-manager configuration
  home.username = "myers";
  home.homeDirectory = "/Users/myers";
  home.stateVersion = "23.11";

  programs.home-manager.enable = true;
}
