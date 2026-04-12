{ pkgs, ... }:
{
  imports = [
    ./opts.nix
    ./keymaps.nix
    ./treesitter.nix
    ./lsp.nix
    ./completion.nix
    ./formatting.nix
    ./linting.nix
    ./ui.nix
    ./git.nix
    ./navigation.nix
    ./editing.nix
    ./dap.nix
    ./lang.nix
    ./extra.nix
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
  };
}
