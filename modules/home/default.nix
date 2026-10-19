{ pkgs, lib, username, homeDirectory, ... }:
let
  # mcp.json references the home directory; expand it at build time since
  # consumers (node stdio servers) don't expand ~ or $HOME in args.
  mcpJson = builtins.replaceStrings
    [ "@homeDir@" ]
    [ homeDirectory ]
    (builtins.readFile ./mcp.json);
  # ynab is personal; pi is the work harness, so it doesn't get it.
  piMcpJson =
    let cfg = builtins.fromJSON mcpJson;
    in builtins.toJSON (cfg // { mcpServers = removeAttrs cfg.mcpServers [ "ynab" ]; });
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

  home.activation.warmObsidianMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    PATH="${lib.makeBinPath [ pkgs.nodejs pkgs.git ]}:$PATH" \
      run ${pkgs.nodejs}/bin/npx -y -p ${lib.escapeShellArg obsidianMcpSpec} true \
      || echo "warning: could not pre-install ${obsidianMcpSpec}; first MCP launch will install it"
  '';
}
