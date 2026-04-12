{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      nvim-scrollbar
      nvim-spectre
      gitgraph-nvim
    ];

    # Worktree picker custom module
    extraFiles."lua/config/worktree-picker.lua".source = ../../../nvim/.config/nvim/lua/config/worktree-picker.lua;

    extraConfigLua = ''
      -- Scrollbar
      require("scrollbar").setup({
        show_in_active_only = true,
        handle = { blend = 0 },
        marks = {
          Search = { color = "#ff9e64" },
          Error = { color = "#db4b4b" },
          Warn = { color = "#e0af68" },
          Info = { color = "#0db9d7" },
          Hint = { color = "#1abc9c" },
          Misc = { color = "#9d7cd8" },
        },
        handlers = {
          cursor = true,
          diagnostic = true,
          gitsigns = true,
          search = false,
        },
      })
      require("scrollbar.handlers.gitsigns").setup()

      -- Spectre
      require("spectre").setup({ open_cmd = "noswapfile vnew" })

      -- Gitgraph
      require("gitgraph").setup({
        git_cmd = "git",
        symbols = {
          merge_commit = "",
          commit = "",
          merge_commit_end = "",
          commit_end = "",
          GVER = "",
          GHOR = "",
          GCLD = "",
          GCRD = "╭",
          GCLU = "",
          GCRU = "",
          GLRU = "",
          GLRD = "",
          GLUD = "",
          GRUD = "",
          GFORKU = "",
          GFORKD = "",
          GRUDCD = "",
          GRUDCU = "",
          GLUDCD = "",
          GLUDCU = "",
          GLRDCL = "",
          GLRDCR = "",
          GLRUCL = "",
          GLRUCR = "",
        },
        format = {
          timestamp = "%H:%M:%S %d-%m-%Y",
          fields = { "hash", "timestamp", "author", "branch_name", "tag" },
        },
        hooks = {
          on_select_commit = function(commit) print("selected commit:", commit.hash) end,
          on_select_range_commit = function(from, to) print("selected range:", from.hash, to.hash) end,
        },
      })
    '';

    keymaps = [
      # Gitgraph
      {
        mode = "n"; key = "<leader>gG";
        action.__raw = ''function() require("gitgraph").draw({}, { all = true, max_count = 5000 }) end'';
        options.desc = "Git graph all";
      }
      {
        mode = "n"; key = "<leader>gGc";
        action.__raw = ''function() require("gitgraph").draw({}, { max_count = 5000 }) end'';
        options.desc = "Git graph current branch";
      }
    ];
  };
}
