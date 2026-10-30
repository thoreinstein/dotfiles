_:
{
  imports = [
    ./opts.nix
    ./autoreload.nix
    ./keymaps.nix
    ./treesitter.nix
    ./lsp.nix
    ./completion.nix
    ./formatting.nix
    ./linting.nix
    ./ui.nix
    ./git.nix
    ./navigation.nix
    ./review.nix
    ./editing.nix
    ./dap.nix
    ./lang.nix
    ./extra.nix
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;

    # Loader for every plugin that sets `lazyLoad` (telescope, nvim-tree, lspsaga,
    # codediff, dap, neotest, ts-autotag): they stay off the runtimepath until
    # their command, filetype or event, instead of all loading at startup.
    plugins.lz-n.enable = true;
  };
}
