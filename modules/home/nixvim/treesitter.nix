{ pkgs, ... }:
{
  programs.nixvim.plugins = {
    treesitter = {
      enable = true;
      settings = {
        highlight.enable = true;
        indent.enable = true;
        incremental_selection = {
          enable = true;
          keymaps = {
            init_selection = "<C-space>";
            node_incremental = "<C-space>";
            scope_incremental = false;
            node_decremental = "<bs>";
          };
        };
      };
      grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        lua
        luadoc
        printf
        vim
        vimdoc
        go
        gomod
        gosum
        gowork
        typescript
        tsx
        javascript
        svelte
        json
        yaml
        bash
        fish
        toml
        dockerfile
        terraform
        hcl
        sql
        git_config
        git_rebase
        gitcommit
        gitignore
        diff
        markdown
        markdown_inline
        html
        css
        gotmpl
        comment
        nix
      ];
    };

    treesitter-context = {
      enable = true;
      settings = {
        max_lines = 3;
      };
    };

    treesitter-textobjects = {
      enable = true;
      settings = {
        move = {
          enable = true;
          set_jumps = true;
          goto_next_start = {
            "]f" = "@function.outer";
            "]c" = "@class.outer";
            "]a" = "@parameter.inner";
          };
          goto_previous_start = {
            "[f" = "@function.outer";
            "[c" = "@class.outer";
            "[a" = "@parameter.inner";
          };
        };
        swap = {
          enable = true;
          swap_next = {
            "<leader>a" = "@parameter.inner";
          };
          swap_previous = {
            "<leader>A" = "@parameter.inner";
          };
        };
      };
    };
  };
}
