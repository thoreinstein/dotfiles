{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    age
    sops
  ];

  # Decrypted to ~/.config/sops-nix/secrets/<name>; MCP wrappers in mcp.nix read them.
  sops = {
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    defaultSopsFile = ../../sops/secrets.yaml;
    secrets = {
      ynab_token = { };
      kroger_client_secret = { };
      mealie_token = { };
    };
  };
}
