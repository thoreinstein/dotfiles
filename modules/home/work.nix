{ pkgs, ... }:
{
  # Everything only the work machine needs. Lists and attrs merge into the shared modules.
  home = {
    packages = with pkgs; [
      codefresh
      # `gcloud components install` can't write to the nix store; declare components here.
      (google-cloud-sdk.withExtraComponents (
        with google-cloud-sdk.components;
        [
          gcloud-crc32c
          gke-gcloud-auth-plugin
        ]
      ))
      k9s
      (writeShellApplication {
        name = "gauth";
        # gcloud comes from PATH: the SDK above, with extra components.
        runtimeInputs = [ fzf coreutils gawk ];
        text = builtins.readFile ../../bin/.bin/gauth;
      })
    ];

    sessionVariables.K9S_CONFIG_DIR = "$HOME/.config/k9s";
  };

  mcpServers = {
    jira = {
      type = "http";
      url = "https://mcp.atlassian.com/v1/mcp";
    };
    glean = {
      type = "http";
      url = "https://pingidentity-be.glean.com/mcp/default";
    };
    firehydrant = {
      type = "stdio";
      command = "bash";
      args = [
        "-c"
        ''exec npx -y firehydrant-mcp@0.0.4 start --transport stdio --api-key "$FIREHYDRANT_API_KEY"''
      ];
    };
  };
}
