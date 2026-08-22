{ username, homeDirectory, ... }:
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
    ./nixvim
    ./pi
    ./ripgrep.nix
    ./starship.nix
    ./tmux.nix
    ./zoxide.nix
    ./zsh.nix
  ];

  # Core home-manager configuration
  home = {
    inherit username homeDirectory;
    stateVersion = "23.11";
    sessionVariables = {
      PI_MEMORY_SNAPSHOT = "per-turn";
      PI_MEMORY_SUMMARIZE_TRANSITIONS = "1";
    };
  };

  programs.home-manager.enable = true;

  home.file = {
    ".mcp.json".source = ./mcp.json;
  };
}
