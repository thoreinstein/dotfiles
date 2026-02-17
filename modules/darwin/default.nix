{ pkgs, ... }:
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

  users.users.myers = {
    name = "myers";
    home = "/Users/myers";
  };

  system.primaryUser = "myers";
  system.stateVersion = 4;
}
