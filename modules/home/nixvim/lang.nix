{ pkgs, ... }:
{
  programs.nixvim = {
    plugins = {
      neotest = {
        enable = true;
        adapters = {
          go.enable = true;
        };
      };
    };

    keymaps = [
      # Neotest (<leader>t — test)
      { mode = "n"; key = "<leader>tt"; action.__raw = ''function() require("neotest").run.run() end''; options.desc = "Run nearest test"; }
      { mode = "n"; key = "<leader>tf"; action.__raw = ''function() require("neotest").run.run(vim.fn.expand("%")) end''; options.desc = "Run test file"; }
      { mode = "n"; key = "<leader>ts"; action.__raw = ''function() require("neotest").summary.toggle() end''; options.desc = "Toggle test summary"; }
      { mode = "n"; key = "<leader>to"; action.__raw = ''function() require("neotest").output.open({ enter_on_open = true }) end''; options.desc = "Show test output"; }
      { mode = "n"; key = "<leader>tO"; action.__raw = ''function() require("neotest").output_panel.toggle() end''; options.desc = "Toggle output panel"; }
      { mode = "n"; key = "<leader>tS"; action.__raw = ''function() require("neotest").run.stop() end''; options.desc = "Stop test"; }
      { mode = "n"; key = "<leader>td"; action.__raw = ''function() require("neotest").run.run({ strategy = "dap" }) end''; options.desc = "Debug nearest test"; }
      { mode = "n"; key = "[T"; action.__raw = ''function() require("neotest").jump.prev({ status = "failed" }) end''; options.desc = "Prev failed test"; }
      { mode = "n"; key = "]T"; action.__raw = ''function() require("neotest").jump.next({ status = "failed" }) end''; options.desc = "Next failed test"; }
    ];

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
