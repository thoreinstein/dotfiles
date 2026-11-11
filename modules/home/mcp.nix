{ config, pkgs, lib, ... }:
let
  shared = (builtins.fromJSON (builtins.readFile ./mcp.json)).mcpServers;
  mcpJson = builtins.toJSON { inherit (config) mcpServers; };
  # ynab is personal; pi is the work harness, so it doesn't get it.
  # pi's MCP adapter hides tools behind its `mcp` proxy; directTools lists
  # codegraph_explore beside read/bash so pi actually reaches for it.
  piMcpJson = builtins.toJSON {
    mcpServers = removeAttrs config.mcpServers [ "ynab" ] // {
      codegraph = config.mcpServers.codegraph // { directTools = [ "codegraph_explore" ]; };
    };
  };
  # npx installs a github: package on first launch (clone + npm install + build).
  # That can outlast pi's 60s MCP startup timeout, so install it at switch time.
  obsidianMcpSpec = lib.last shared."obsidian-mcp".args;
  # Claude Desktop launches servers without the shell env, so each wrapper sets its own
  # PATH and reads its secret from sops-nix at start.
  ynabMcp = pkgs.writeShellScript "ynab-mcp" ''
    export PATH="${lib.makeBinPath [ pkgs.nodejs ]}:/usr/bin:/bin"
    YNAB_API_TOKEN=$(cat ${config.sops.secrets.ynab_token.path})
    export YNAB_API_TOKEN
    exec npx -y ynab-mcp-server@0.4.1
  '';
  krogerMcp = pkgs.writeShellScript "kroger-mcp" ''
    KROGER_CLIENT_SECRET=$(cat ${config.sops.secrets.kroger_client_secret.path})
    export KROGER_CLIENT_SECRET
    export KROGER_CLIENT_ID=personalmcpserver-bbcj1nxg
    export KROGER_REDIRECT_URI=http://localhost:8000/callback
    export KROGER_USER_ZIP_CODE=41075
    exec ${pkgs.uv}/bin/uvx kroger-mcp
  '';
  # Mealie runs on the Mac mini; the MacBook reaches it over Bonjour on the LAN.
  mealieMcp = pkgs.writeShellScript "mealie-mcp" ''
    MEALIE_API_TOKEN=$(cat ${config.sops.secrets.mealie_token.path})
    export MEALIE_API_TOKEN
    export MEALIE_BASE_URL=http://jims-mac-mini.local:9925
    exec ${pkgs.uv}/bin/uvx --from git+https://github.com/thoreinstein/mcp-mealie@5f4748cbe52b8f67aba81f8df7ff4ba4270c3b4d mcp-mealie
  '';
in
{
  options.mcpServers = lib.mkOption {
    type = lib.types.attrsOf lib.types.attrs;
    description = "MCP servers written to ~/.mcp.json and pi's mcp.json.";
  };

  config = {
    mcpServers = shared // {
      ynab = {
        type = "stdio";
        command = "${ynabMcp}";
        args = [ ];
      };
    };

    programs.mcp = {
      enable = true;
      servers = {
        context7 = {
          url = "https://mcp.context7.com/mcp";
        };
        exa = {
          url = "https://mcp.exa.ai/mcp?tools=web_search_exa";
        };
        grep_app = {
          url = "https://mcp.grep.app";
        };
      };
    };

    # obsidian-mcp refuses every vault tool until it has a vault root. The config file reaches
    # every client (Claude Code, Claude Desktop, pi, recall); an env var in mcp.json would not.
    xdg.configFile."obsidian-mcp/config.json".text = builtins.toJSON {
      vault_path = "${config.home.homeDirectory}/Documents/second_brain";
    };

    home = {
      file = {
        ".mcp.json".text = mcpJson;
        # pi >= 0.99 reads native MCP config from here
        ".pi/agent/mcp.json".text = piMcpJson;
      };

      # The install also tells recall where obsidian-mcp's entry point landed (bin/recall reads
      # ~/.local/state/recall/obsidian-mcp), so recall runs it directly instead of through npx.
      # Skipped while the spec is unchanged and the recorded path still exists, so a switch stays
      # fast and works offline.
      activation.warmObsidianMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        state="''${XDG_STATE_HOME:-$HOME/.local/state}/recall"
        if [ "$(cat "$state/obsidian-mcp.spec" 2>/dev/null)" != ${lib.escapeShellArg obsidianMcpSpec} ] \
          || [ ! -f "$(cat "$state/obsidian-mcp" 2>/dev/null)" ]; then
          if bin=$(PATH="${lib.makeBinPath [ pkgs.nodejs pkgs.git ]}:$PATH" \
              ${pkgs.nodejs}/bin/npx -y -p ${lib.escapeShellArg obsidianMcpSpec} sh -c 'command -v obsidian-mcp') \
            && [ -n "$bin" ]; then
            run mkdir -p "$state"
            if [[ ! -v DRY_RUN ]]; then
              readlink -f "$bin" >"$state/obsidian-mcp"
              printf '%s\n' ${lib.escapeShellArg obsidianMcpSpec} >"$state/obsidian-mcp.spec"
            fi
          else
            echo "warning: could not install ${obsidianMcpSpec}; recall has no vault index until the next switch"
          fi
        fi
      '';

      activation.claudeDesktopMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        cfg="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
        if [ -f "$cfg" ]; then
          entries=$(${pkgs.jq}/bin/jq -n \
            --arg cmd "${pkgs.nodejs}/bin/npx" \
            --arg spec ${lib.escapeShellArg obsidianMcpSpec} \
            --arg path "${lib.makeBinPath [ pkgs.nodejs pkgs.git ]}:/usr/bin:/bin" \
            --arg ynab "${ynabMcp}" \
            --arg kroger "${krogerMcp}" \
            --arg mealie "${mealieMcp}" \
            '{"obsidian-mcp": {command: $cmd, args: ["-y", $spec], env: {PATH: $path}},
              ynab: {command: $ynab, args: []},
              kroger: {command: $kroger, args: []},
              mealie: {command: $mealie, args: []}}')
          tmp=$(mktemp "$(dirname "$cfg")/.claude_desktop_config.XXXXXX")
          if [ -n "$entries" ] && ${pkgs.jq}/bin/jq --argjson e "$entries" '.mcpServers += $e' "$cfg" > "$tmp" && [ -s "$tmp" ]; then
            if cmp -s "$tmp" "$cfg"; then rm -f "$tmp"; else chmod 600 "$tmp"; run mv "$tmp" "$cfg"; fi
          else
            rm -f "$tmp"
            echo "warning: could not update Claude Desktop config; left unchanged"
          fi
        fi
      '';
    };
  };
}
