{ pkgs, username, homeDirectory, ... }:
{
  imports = [
    ./homebrew.nix
    ./system.nix
  ];

  ids.gids.nixbld = 350;
  nix.settings.experimental-features = "nix-command flakes";

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  programs.zsh.enable = true;

  users.users.${username} = {
    name = username;
    home = homeDirectory;
  };

  system.primaryUser = username;
  system.stateVersion = 4;
}
