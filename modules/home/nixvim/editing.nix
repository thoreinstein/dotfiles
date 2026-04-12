_:
{
  programs.nixvim.plugins = {
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
}
