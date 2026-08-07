_:
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

          # blink's own snippet engine (expands via vim.snippet) instead of
          # luasnip. Its default source scans the runtimepath for
          # friendly-snippets lazily, so the same snippets stay available
          # without luasnip's ~11ms of startup.
          snippets = {
            preset = "default";
          };

          completion = {
            documentation = {
              auto_show = true;
              auto_show_delay_ms = 100;
            };
          };
        };
      };

      friendly-snippets.enable = true;
    };
  };
}
