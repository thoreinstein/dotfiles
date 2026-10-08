{ username, homeDirectory, ... }:
let
  # mcp.json references the home directory; expand it at build time since
  # consumers (node stdio servers) don't expand ~ or $HOME in args.
  mcpJson = builtins.replaceStrings
    [ "@homeDir@" ]
    [ homeDirectory ]
    (builtins.readFile ./mcp.json);
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
    # pi >= 0.99 reads native MCP config from here (same file, both paths)
    ".pi/agent/mcp.json".text = mcpJson;
  };
}
