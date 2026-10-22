{ lib, pkgs, username, homeDirectory, ... }:
{
  imports = [
    ./aerospace.nix
    ./homebrew.nix
    ./system.nix
  ];

  ids.gids.nixbld = 350;
  nix = {
    settings.experimental-features = "nix-command flakes";
    # Keep the store bounded; launchd runs gc weekly (default Sun 03:15).
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
    optimise.automatic = true;
  };
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "claude-code" "rtk" ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = false; # home-manager handles compinit
  };

  users.users.${username} = {
    name = username;
    home = homeDirectory;
  };

  system.primaryUser = username;
  system.stateVersion = 4;
}
