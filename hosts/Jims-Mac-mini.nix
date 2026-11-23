{ config, homeDirectory, inputs, pkgs, lib, ... }:
let
  # Mealie MCP over Streamable HTTP for the claude.ai connector, from the fork
  # (github.com/thoreinstein/mcp-mealie). Loopback only; the tunnel publishes it
  # as recipes-mcp.myerslabs.dev behind the MCP portal (myerslabs_iac); an edge
  # WAF rule requires the portal's upstream token. The token is read from
  # the sops secret at start so it never lands in the plist or the nix store.
  mealieMcpHttp = pkgs.writeShellScript "mealie-mcp-http" ''
    export PATH="${pkgs.git}/bin:/usr/bin:/bin"
    MEALIE_API_TOKEN=$(cat ${config.sops.secrets.mealie_token.path})
    export MEALIE_API_TOKEN
    export MEALIE_BASE_URL=http://127.0.0.1:9925
    exec ${pkgs.uv}/bin/uvx --from git+https://github.com/thoreinstein/mcp-mealie@685c88db58c32126e098c4c6d861fe7231566a23 \
      mcp-mealie --http --port 9930 --allowed-host recipes-mcp.myerslabs.dev
  '';

  # Grocy MCP over Streamable HTTP for the claude.ai connector, from the fork
  # (github.com/thoreinstein/grocy-mcp). Loopback only; the tunnel publishes it
  # as grocy-mcp.myerslabs.dev behind the MCP portal (myerslabs_iac); an edge
  # WAF rule requires the portal's upstream token, so the server's own auth is
  # off. GROCY_API_URL and GROCY_API_KEY come from
  # ~/.config/grocy-mcp/env (0600, written at Grocy setup), read at start.
  grocyMcpHttp = pkgs.writeShellScript "grocy-mcp-http" ''
    export PATH="${pkgs.git}/bin:/usr/bin:/bin"
    set -a
    . ${homeDirectory}/.config/grocy-mcp/env
    set +a
    exec ${pkgs.uv}/bin/uvx --from git+https://github.com/thoreinstein/grocy-mcp@2830ffd91081411660aba917a4924ff49099af32 \
      grocy-mcp --transport http --port 9941 --public-host grocy-mcp.myerslabs.dev --no-auth
  '';

  # Kroger MCP over Streamable HTTP for the claude.ai connector. Loopback only; the
  # tunnel publishes it as kroger-mcp.myerslabs.dev behind the MCP portal
  # (myerslabs_iac); an edge WAF rule requires the portal's upstream token. Same env
  # as the stdio wrapper in modules/home/mcp.nix, so both share one token and cart.
  krogerMcpHttp = pkgs.writeShellScript "kroger-mcp-http" ''
    KROGER_CLIENT_SECRET=$(cat ${config.sops.secrets.kroger_client_secret.path})
    export KROGER_CLIENT_SECRET
    export KROGER_CLIENT_ID=personalmcpserver-bbcj1nxg
    export KROGER_REDIRECT_URI=http://localhost:8000/callback
    export KROGER_USER_ZIP_CODE=41075
    exec ${pkgs.uv}/bin/uvx kroger-mcp --transport streamable-http --host 127.0.0.1 --port 9950
  '';

  # YNAB MCP over Streamable HTTP for the claude.ai connector. ynab-mcp-server only
  # speaks stdio, so mcp-proxy bridges it. Loopback only; the tunnel publishes it as
  # ynab-mcp.myerslabs.dev behind the MCP portal (myerslabs_iac); an edge WAF rule
  # requires the portal's upstream token.
  ynabMcpHttp = pkgs.writeShellScript "ynab-mcp-http" ''
    export PATH="${lib.makeBinPath [ pkgs.nodejs ]}:/usr/bin:/bin"
    YNAB_API_TOKEN=$(cat ${config.sops.secrets.ynab_token.path})
    export YNAB_API_TOKEN
    exec ${pkgs.uv}/bin/uvx mcp-proxy@0.15.0 --host 127.0.0.1 --port 9960 \
      --allowed-host ynab-mcp.myerslabs.dev --pass-environment \
      -- npx -y ynab-mcp-server@0.4.1
  '';

  # Obsidian vault MCP over Streamable HTTP for the claude.ai connector. obsidian-mcp only
  # speaks stdio, so mcp-proxy bridges it. Same pinned package as the stdio clients
  # (modules/home/mcp.json) and the same vault root (~/.config/obsidian-mcp/config.json).
  # Loopback only; the tunnel publishes it as obsidian-mcp.myerslabs.dev behind the MCP
  # portal (myerslabs_iac); an edge WAF rule requires the portal's upstream token.
  obsidianMcpSpec = lib.last (builtins.fromJSON (builtins.readFile ../modules/home/mcp.json)).mcpServers."obsidian-mcp".args;
  obsidianMcpHttp = pkgs.writeShellScript "obsidian-mcp-http" ''
    export PATH="${lib.makeBinPath [ pkgs.nodejs pkgs.git ]}:/usr/bin:/bin"
    exec ${pkgs.uv}/bin/uvx mcp-proxy@0.15.0 --host 127.0.0.1 --port 9980 \
      --allowed-host obsidian-mcp.myerslabs.dev --pass-environment \
      -- npx -y ${lib.escapeShellArg obsidianMcpSpec}
  '';
in
{
  launchd.agents = {
    # officed: the office daemon (github.com/thoreinstein/office_daemon). The
    # binary is not built by nix: it must keep a stable path and signing
    # identifier so macOS's Bluetooth and Local Network grants survive updates.
    # Install or update it with office_daemon's scripts/install.sh.
    officed = {
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
    office-bridge = {
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
    # plus the grocy, kroger, ynab, office and obsidian MCP hostnames, all behind the MCP portal
    # (myerslabs_iac; an edge WAF rule requires its upstream token). A login agent, not a boot daemon: FileVault means nothing
    # runs before login anyway, and Mealie's Docker Desktop only starts at login.
    # ~/.cloudflared holds config.yml, the tunnel credentials JSON and cert.pem
    # (made by `cloudflared tunnel login` / `tunnel create mealie`), not managed here.
    cloudflared-mealie = {
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

    mealie-mcp-http = {
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

    grocy-mcp-http = {
      enable = true;
      config = {
        Label = "com.thoreinstein.grocy-mcp-http";
        ProgramArguments = [ "${grocyMcpHttp}" ];
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 30;
        StandardOutPath = "${homeDirectory}/Library/Logs/grocy-mcp-http.log";
        StandardErrorPath = "${homeDirectory}/Library/Logs/grocy-mcp-http.log";
      };
    };

    # officemcp: the MCP server for officed (office_daemon's cmd/officemcp).
    # Loopback only; the tunnel publishes it as office-mcp.myerslabs.dev for
    # the Cloudflare MCP portal, so it has no auth of its own. It talks to
    # officed's socket.
    officemcp-http = {
      enable = true;
      config = {
        Label = "com.thoreinstein.officemcp-http";
        ProgramArguments = [
          "${inputs.office-daemon.packages.${pkgs.stdenv.hostPlatform.system}.officemcp}/bin/officemcp"
          "-addr"
          "127.0.0.1:9970"
          "-allowed-host"
          "office-mcp.myerslabs.dev"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 30;
        StandardOutPath = "${homeDirectory}/Library/Logs/officemcp-http.log";
        StandardErrorPath = "${homeDirectory}/Library/Logs/officemcp-http.log";
      };
    };

    kroger-mcp-http = {
      enable = true;
      config = {
        Label = "com.thoreinstein.kroger-mcp-http";
        ProgramArguments = [ "${krogerMcpHttp}" ];
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 30;
        StandardOutPath = "${homeDirectory}/Library/Logs/kroger-mcp-http.log";
        StandardErrorPath = "${homeDirectory}/Library/Logs/kroger-mcp-http.log";
      };
    };

    ynab-mcp-http = {
      enable = true;
      config = {
        Label = "com.thoreinstein.ynab-mcp-http";
        ProgramArguments = [ "${ynabMcpHttp}" ];
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 30;
        StandardOutPath = "${homeDirectory}/Library/Logs/ynab-mcp-http.log";
        StandardErrorPath = "${homeDirectory}/Library/Logs/ynab-mcp-http.log";
      };
    };

    obsidian-mcp-http = {
      enable = true;
      config = {
        Label = "com.thoreinstein.obsidian-mcp-http";
        ProgramArguments = [ "${obsidianMcpHttp}" ];
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 30;
        StandardOutPath = "${homeDirectory}/Library/Logs/obsidian-mcp-http.log";
        StandardErrorPath = "${homeDirectory}/Library/Logs/obsidian-mcp-http.log";
      };
    };
  };
}
