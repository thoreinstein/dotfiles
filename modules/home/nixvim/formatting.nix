{ pkgs, ... }:
{
  programs.nixvim = {
    plugins.conform-nvim = {
      enable = true;
      settings = {
        formatters_by_ft = {
          css = [ "prettierd" ];
          go = [ "goimports" "gofmt" ];
          graphql = [ "prettierd" ];
          handlebars = [ "prettierd" ];
          hcl = [ "tofu_fmt" "terragrunt_hclfmt" ];
          html = [ "prettierd" ];
          javascript = [ "prettierd" ];
          javascriptreact = [ "prettierd" ];
          json = [ "prettierd" ];
          jsonc = [ "prettierd" ];
          less = [ "prettierd" ];
          lua = [ "stylua" ];
          markdown = [ "prettierd" ];
          python = [ "isort" "black" ];
          rust = [ "rustfmt" ];
          scss = [ "prettierd" ];
          sh = [ "shfmt" ];
          svelte = [ "prettierd" ];
          terraform = [ "tofu_fmt" ];
          "terraform-vars" = [ "tofu_fmt" ];
          typescript = [ "prettierd" ];
          typescriptreact = [ "prettierd" ];
          vue = [ "prettierd" ];
          zig = [ "zigfmt" ];
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
                lsp_format = "fallback",
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
            require("conform").format({ async = true, lsp_format = "fallback" })
          end
        '';
        options.desc = "Format buffer";
      }
      {
        mode = "v";
        key = "<leader>rF";
        action.__raw = ''
          function()
            -- The selection as a range; without one conform formats the whole buffer.
            local s, e = vim.fn.line("v"), vim.fn.line(".")
            if s > e then s, e = e, s end
            local last = vim.api.nvim_buf_get_lines(0, e - 1, e, false)[1] or ""
            require("conform").format({
              async = true,
              lsp_format = "fallback",
              range = { start = { s, 0 }, ["end"] = { e, #last } },
            })
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
      prettierd
      shfmt
      stylua
      zig
    ];
  };
}
