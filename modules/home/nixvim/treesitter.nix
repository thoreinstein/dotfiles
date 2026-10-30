{ pkgs, ... }:
let
  # nvim-treesitter-textobjects (main branch) no longer builds keymaps from its
  # config table; each motion is a plain keymap into its move/swap modules.
  move = key: fn: query: desc: {
    mode = [ "n" "x" "o" ];
    inherit key;
    action.__raw = "function() require(\"nvim-treesitter-textobjects.move\").${fn}(\"${query}\", \"textobjects\") end";
    options.desc = desc;
  };
  swap = key: fn: query: desc: {
    mode = "n";
    inherit key;
    action.__raw = "function() require(\"nvim-treesitter-textobjects.swap\").${fn}(\"${query}\") end";
    options.desc = desc;
  };
in
{
  programs.nixvim.keymaps = [
    (move "]f" "goto_next_start" "@function.outer" "Next function")
    (move "[f" "goto_previous_start" "@function.outer" "Previous function")
    (move "]k" "goto_next_start" "@class.outer" "Next class") # ]c/[c are the diff-hunk motions
    (move "[k" "goto_previous_start" "@class.outer" "Previous class")
    (move "]a" "goto_next_start" "@parameter.inner" "Next parameter")
    (move "[a" "goto_previous_start" "@parameter.inner" "Previous parameter")
    (swap "<leader>a" "swap_next" "@parameter.inner" "Swap with next parameter")
    (swap "<leader>A" "swap_previous" "@parameter.inner" "Swap with previous parameter")
  ];

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
      grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; let
        # tree-sitter-nix ships its own queries using #is-not? (unregistered by
        # nvim-treesitter) which shadow the plugin's queries; drop them.
        # See nvim-treesitter#6870 / nix-community/tree-sitter-nix#84.
        nix-clean = nix.overrideAttrs (_: { postInstall = "rm -rf $out/queries"; });
      in
      [
        nix-clean
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
        python
        rust
        css
        gotmpl
        comment
        zig
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
      settings.move.set_jumps = true;
    };
  };
}
