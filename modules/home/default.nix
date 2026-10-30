{ pkgs, lib, username, homeDirectory, ... }:
let
  # mcp.json references the home directory; expand it at build time since
  # consumers (node stdio servers) don't expand ~ or $HOME in args.
  mcpJson = builtins.replaceStrings
    [ "@homeDir@" ]
    [ homeDirectory ]
    (builtins.readFile ./mcp.json);
  # ynab is personal; pi is the work harness, so it doesn't get it.
  # pi's MCP adapter hides tools behind its `mcp` proxy; directTools lists
  # codegraph_explore beside read/bash so pi actually reaches for it.
  piMcpJson =
    let cfg = builtins.fromJSON mcpJson;
    in builtins.toJSON (cfg // {
      mcpServers = removeAttrs cfg.mcpServers [ "ynab" ] // {
        codegraph = cfg.mcpServers.codegraph // { directTools = [ "codegraph_explore" ]; };
      };
    });
  # npx installs a github: package on first launch (clone + npm install + build).
  # That can outlast pi's 60s MCP startup timeout, so install it at switch time.
  obsidianMcpSpec = lib.last (builtins.fromJSON mcpJson).mcpServers."obsidian-mcp".args;
in
{
  imports = [
    ./atuin.nix
    ./bat.nix
    ./bin.nix
    ./claude.nix
    ./cli.nix
    ./direnv.nix
    ./engram-vault-sync.nix
    ./mise.nix
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
    ".mcp.json".text = mcpJson;
    # pi >= 0.99 reads native MCP config from here
    ".pi/agent/mcp.json".text = piMcpJson;
  };

  # The install also tells recall where obsidian-mcp's entry point landed (bin/recall reads
  # ~/.local/state/recall/obsidian-mcp), so recall runs it directly instead of through npx.
  # Skipped while the spec is unchanged and the recorded path still exists, so a switch stays
  # fast and works offline.
  home.activation.warmObsidianMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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

  home.activation.claudeDesktopObsidianMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cfg="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
    if [ -f "$cfg" ]; then
      entry=$(${pkgs.jq}/bin/jq -n \
        --arg cmd "${pkgs.nodejs}/bin/npx" \
        --arg spec ${lib.escapeShellArg obsidianMcpSpec} \
        --arg path "${lib.makeBinPath [ pkgs.nodejs pkgs.git ]}:/usr/bin:/bin" \
        '{command: $cmd, args: ["-y", $spec], env: {PATH: $path}}')
      tmp=$(mktemp "$(dirname "$cfg")/.claude_desktop_config.XXXXXX")
      if [ -n "$entry" ] && ${pkgs.jq}/bin/jq --argjson e "$entry" '.mcpServers["obsidian-mcp"] = $e' "$cfg" > "$tmp" && [ -s "$tmp" ]; then
        if cmp -s "$tmp" "$cfg"; then rm -f "$tmp"; else chmod 600 "$tmp"; run mv "$tmp" "$cfg"; fi
      else
        rm -f "$tmp"
        echo "warning: could not update Claude Desktop config; left unchanged"
      fi
    fi
  '';
}
