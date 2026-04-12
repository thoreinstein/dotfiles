{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      go-nvim
      guihua-lua
      vim-helm
      markview-nvim
    ];

    extraConfigLua = ''
      require("go").setup({
        lsp_cfg = {
          settings = {
            gopls = {
              buildFlags = {},
              analyses = { unusedparams = true },
              staticcheck = true,
              gofumpt = true,
            },
          },
        },
        lsp_keymaps = false,
        fmt_on_save = false,
        lsp_inlay_hints = { enable = true },
        trouble = true,
        dap_debug = true,
        test_runner = "ginkgo",
        run_in_floaterm = false,
        icons = { breakpoint = "🔴", currentpos = "🔶" },
      })
    '';
  };
}
