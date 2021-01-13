{ pkgs, modulesPath, lib, ... }:
{
  imports = lib.optional (builtins.pathExists ./do-userdata.nix) ./do-userdata.nix ++ [
    (modulesPath + "/virtualisation/digital-ocean-config.nix")
  ];

  users.groups = {
    sudo = { };
  };

  security.sudo.wheelNeedsPassword = false;

  users.users.janders223 = {
    name = "Jim Anders";
    createHome = true;
    group = "janders223";
    extraGroups = [ "wheel" ];
    isNormalUser = true;
    shell = pkgs.zsh;
  };

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  services.openssh = {
    enable = true;
    ports = [ 3518 ];
    passwordAuthentication = false;
  };
}
