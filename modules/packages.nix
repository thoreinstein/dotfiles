{ pkgs, ... }:

with pkgs; [
    curl
    exa
    fd
    gcc
    gitAndTools.hub
		ledger
    llvm
    ripgrep
		spotifyd
		spotify-tui
    tree-sitter
]
