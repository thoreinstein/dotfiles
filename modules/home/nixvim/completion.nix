{ pkgs, ... }:
{
  programs.nixvim = {
    plugins = {
      blink-cmp = {
        enable = true;
        settings = {
          keymap = {
            "<C-space>" = [ "show" "show_documentation" "hide_documentation" ];
            "<C-e>" = [ "hide" ];
            "<C-p>" = [ "select_prev" "fallback" ];
            "<C-n>" = [ "select_next" "fallback" ];
            "<Tab>" = [ "select_next" "fallback" ];
            "<S-Tab>" = [ "select_prev" "fallback" ];
            "<CR>" = [ "accept" "fallback" ];
            "<C-d>" = [ "scroll_documentation_down" "fallback" ];
            "<C-f>" = [ "scroll_documentation_up" "fallback" ];
          };

          appearance = {
            use_nvim_cmp_as_default = true;
            nerd_font_variant = "mono";
          };

          sources = {
            default = [ "lsp" "path" "snippets" "buffer" ];
          };

          snippets = {
            preset = "luasnip";
          };

          completion = {
            documentation = {
              auto_show = true;
              auto_show_delay_ms = 100;
            };
          };
        };
      };

      luasnip = {
        enable = true;
        settings = {
          history = true;
          updateevents = "TextChanged,TextChangedI";
        };
        fromVscode = [{ }];
      };

      friendly-snippets.enable = true;
    };

    extraConfigLua = ''
      -- Unlink snippet on InsertLeave
      vim.api.nvim_create_autocmd("InsertLeave", {
        callback = function()
          if
            require("luasnip").session.current_nodes[vim.api.nvim_get_current_buf()]
            and not require("luasnip").session.jump_active
          then
            require("luasnip").unlink_current()
          end
        end,
      })
    '';
  };
}
