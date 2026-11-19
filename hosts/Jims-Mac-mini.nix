{ config, homeDirectory, pkgs, ... }:
let
  # Mealie MCP over Streamable HTTP for the claude.ai connector, from the fork
  # (github.com/thoreinstein/mcp-mealie). Loopback only; the tunnel publishes it
  # as recipes-mcp.myerslabs.dev behind Cloudflare Access. The token is read from
  # the sops secret at start so it never lands in the plist or the nix store.
  mealieMcpHttp = pkgs.writeShellScript "mealie-mcp-http" ''
    export PATH="${pkgs.git}/bin:/usr/bin:/bin"
    MEALIE_API_TOKEN=$(cat ${config.sops.secrets.mealie_token.path})
    export MEALIE_API_TOKEN
    export MEALIE_BASE_URL=http://127.0.0.1:9925
    exec ${pkgs.uv}/bin/uvx --from git+https://github.com/thoreinstein/mcp-mealie@685c88db58c32126e098c4c6d861fe7231566a23 \
      mcp-mealie --http --port 9930 --allowed-host recipes-mcp.myerslabs.dev
  '';
in
{
  programs.pi-coding-agent.settings = {
    # strata runs on the gaming PC, which isn't always on.
    defaultProvider = "kimi-coding";
    defaultModel = "k3";
  };

  # officed: the office daemon (github.com/thoreinstein/office_daemon). The
  # binary is not built by nix: it must keep a stable path and signing
  # identifier so macOS's Bluetooth and Local Network grants survive updates.
  # Install or update it with office_daemon's scripts/install.sh.
  launchd.agents.officed = {
    enable = true;
    config = {
      Label = "com.thoreinstein.officed";
      ProgramArguments = [ "${homeDirectory}/.local/bin/officed" ];
      RunAtLoad = true;
      KeepAlive.SuccessfulExit = false;
      ThrottleInterval = 30;
      ProcessType = "Interactive";
      # Routine logs go to the unified log; this file only catches panics.
      StandardOutPath = "${homeDirectory}/Library/Logs/officed.log";
      StandardErrorPath = "${homeDirectory}/Library/Logs/officed.log";
    };
  };

  # office-bridge: Google Home switches for officed's modes (office_daemon's
  # bridge/). scripts/install.sh installs it to ~/.local/lib/office-bridge.
  launchd.agents.office-bridge = {
    enable = true;
    config = {
      Label = "com.thoreinstein.office-bridge";
      ProgramArguments = [ "${pkgs.nodejs_24}/bin/node" "${homeDirectory}/.local/lib/office-bridge/index.js" ];
      EnvironmentVariables.MATTER_STORAGE_PATH = "${homeDirectory}/.local/state/office/bridge";
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 30;
      StandardOutPath = "${homeDirectory}/Library/Logs/office-bridge.log";
      StandardErrorPath = "${homeDirectory}/Library/Logs/office-bridge.log";
    };
  };

  # Cloudflare tunnel "mealie": recipes.myerslabs.dev -> Mealie on :9925 (Mealie's
  # own login, no Access) and recipes-mcp.myerslabs.dev -> mealie-mcp on :9930
  # (behind Cloudflare Access). A login agent, not a boot daemon: FileVault means nothing
  # runs before login anyway, and Mealie's Docker Desktop only starts at login.
  # ~/.cloudflared holds config.yml, the tunnel credentials JSON and cert.pem
  # (made by `cloudflared tunnel login` / `tunnel create mealie`), not managed here.
  launchd.agents.cloudflared-mealie = {
    enable = true;
    config = {
      Label = "com.thoreinstein.cloudflared-mealie";
      ProgramArguments = [
        "${pkgs.cloudflared}/bin/cloudflared"
        "tunnel"
        "--no-autoupdate"
        "--config"
        "${homeDirectory}/.cloudflared/config.yml"
        "run"
        "mealie"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 30;
      StandardOutPath = "${homeDirectory}/Library/Logs/cloudflared-mealie.log";
      StandardErrorPath = "${homeDirectory}/Library/Logs/cloudflared-mealie.log";
    };
  };

  launchd.agents.mealie-mcp-http = {
    enable = true;
    config = {
      Label = "com.thoreinstein.mealie-mcp-http";
      ProgramArguments = [ "${mealieMcpHttp}" ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 30;
      StandardOutPath = "${homeDirectory}/Library/Logs/mealie-mcp-http.log";
      StandardErrorPath = "${homeDirectory}/Library/Logs/mealie-mcp-http.log";
    };
  };
}
