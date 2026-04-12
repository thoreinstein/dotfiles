{ pkgs, ... }:
{
  programs.nixvim = {
    plugins.conform-nvim = {
      enable = true;
      settings = {
        formatters_by_ft = {
          css = [ "prettier" ];
          go = [ "goimports" "gofmt" ];
          graphql = [ "prettier" ];
          handlebars = [ "prettier" ];
          html = [ "prettier" ];
          javascript = [ "prettier" ];
          javascriptreact = [ "prettier" ];
          json = [ "prettier" ];
          jsonc = [ "prettier" ];
          less = [ "prettier" ];
          lua = [ "stylua" ];
          markdown = [ "prettier" ];
          python = [ "isort" "black" ];
          rust = [ "rustfmt" ];
          scss = [ "prettier" ];
          sh = [ "shfmt" ];
          svelte = [ "prettier" ];
          typescript = [ "prettier" ];
          typescriptreact = [ "prettier" ];
          vue = [ "prettier" ];
        };
        format_on_save = {
          __raw = ''
            function(bufnr)
              if vim.g.disable_autoformat then
                return
              end
              local filepath = vim.api.nvim_buf_get_name(bufnr)
              if filepath:match("templates/.*%.ya?ml$") then
                return false
              end
              return {
                timeout_ms = 500,
                lsp_fallback = true,
              }
            end
          '';
        };
      };
    };

    keymaps = [
      {
        mode = [ "n" "v" ];
        key = "<leader>rf";
        action.__raw = ''
          function()
            require("conform").format({ async = true, lsp_fallback = true })
          end
        '';
        options.desc = "Format buffer";
      }
      {
        mode = "v";
        key = "<leader>rF";
        action.__raw = ''
          function()
            require("conform").format({ async = true, lsp_fallback = true })
          end
        '';
        options.desc = "Format selection";
      }
      {
        mode = "n";
        key = "<leader>rt";
        action.__raw = ''
          function()
            vim.g.disable_autoformat = not vim.g.disable_autoformat
            vim.notify("Format on save: " .. (vim.g.disable_autoformat and "OFF" or "ON"))
          end
        '';
        options.desc = "Toggle format on save";
      }
    ];

    extraPackages = with pkgs; [
      gofumpt
      gotools
      prettierd
      black
      isort
      shfmt
      yamlfmt
      stylua
      rustfmt
    ];
  };
}
