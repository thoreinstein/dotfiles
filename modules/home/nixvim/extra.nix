{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      nvim-scrollbar
      nvim-spectre
      # gitgraph-nvim — not in nixpkgs, needs buildVimPlugin with pinned hash
    ];

    extraConfigLua = ''
      -- Scrollbar
      require("scrollbar").setup({
        show_in_active_only = true,
        handle = { blend = 0 },
        marks = {
          Search = { color = "#ff9e64" },
          Error = { color = "#db4b4b" },
          Warn = { color = "#e0af68" },
          Info = { color = "#0db9d7" },
          Hint = { color = "#1abc9c" },
          Misc = { color = "#9d7cd8" },
        },
        handlers = {
          cursor = true,
          diagnostic = true,
          gitsigns = true,
          search = false,
        },
      })
      require("scrollbar.handlers.gitsigns").setup()

      -- Spectre
      require("spectre").setup({ open_cmd = "noswapfile vnew" })
    '';
  };
}
