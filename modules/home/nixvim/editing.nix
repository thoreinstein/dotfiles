{ pkgs, ... }:
{
  programs.nixvim = {
    plugins = {
      nvim-autopairs = {
        enable = true;
        settings = {
          fast_wrap = { };
          disable_filetype = [ "TelescopePrompt" "vim" ];
        };
      };

      nvim-surround = {
        enable = true;
      };

      mini = {
        enable = true;
        modules = {
          ai = {
            n_lines = 500;
            custom_textobjects = {
              o = {
                __raw = ''
                  require("mini.ai").gen_spec.treesitter({
                    a = { "@block.outer", "@conditional.outer", "@loop.outer" },
                    i = { "@block.inner", "@conditional.inner", "@loop.inner" },
                  }, {})
                '';
              };
              f = {
                __raw = ''
                  require("mini.ai").gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {})
                '';
              };
              c = {
                __raw = ''
                  require("mini.ai").gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {})
                '';
              };
              a = {
                __raw = ''
                  require("mini.ai").gen_spec.treesitter({ a = "@parameter.outer", i = "@parameter.inner" }, {})
                '';
              };
            };
          };
        };
      };
    };

    keymaps = [
      { mode = "n"; key = "<leader>sr"; action.__raw = ''function() require("spectre").open() end''; options.desc = "Search and replace"; }
      { mode = "n"; key = "<leader>sw"; action.__raw = ''function() require("spectre").open_visual({ select_word = true }) end''; options.desc = "Search word under cursor"; }
      { mode = "v"; key = "<leader>sw"; action.__raw = ''function() require("spectre").open_visual() end''; options.desc = "Search selection"; }
      { mode = "n"; key = "<leader>sf"; action.__raw = ''function() require("spectre").open_file_search({ select_word = true }) end''; options.desc = "Search in current file"; }
      { mode = "n"; key = "<leader>sR"; action.__raw = ''function() require("spectre").replace() end''; options.desc = "Replace all"; }
    ];
  };
}
