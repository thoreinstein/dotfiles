{ pkgs, ... }:
{
  programs.nixvim = {
    plugins = {
      telescope = {
        enable = true;
        settings = {
          defaults = {
            prompt_prefix = "   ";
            selection_caret = " ";
            entry_prefix = " ";
            sorting_strategy = "ascending";
            layout_config = {
              horizontal = {
                prompt_position = "top";
                preview_width = 0.55;
              };
              width = 0.87;
              height = 0.80;
            };
            mappings = {
              n = {
                q = {
                  __raw = "require('telescope.actions').close";
                };
              };
            };
          };
        };
      };

      flash = {
        enable = true;
        settings = {
          modes = {
            char = { jump_labels = true; };
            search = { enabled = false; };
          };
        };
      };

      oil = {
        enable = true;
        settings = {
          default_file_explorer = false;
          columns = [ "icon" ];
          keymaps = {
            "g?" = "actions.show_help";
            "<CR>" = "actions.select";
            "<C-v>" = "actions.select_vsplit";
            "<C-s>" = "actions.select_split";
            "<C-t>" = "actions.select_tab";
            "<C-p>" = "actions.preview";
            "<C-c>" = "actions.close";
            "<C-r>" = "actions.refresh";
            "-" = "actions.parent";
            "_" = "actions.open_cwd";
            "`" = "actions.cd";
            "~" = "actions.tcd";
            "gs" = "actions.change_sort";
            "gx" = "actions.open_external";
            "g." = "actions.toggle_hidden";
          };
          view_options = {
            show_hidden = true;
          };
        };
      };

      nvim-tree = {
        enable = true;
        settings = {
          filters.dotfiles = false;
          disable_netrw = true;
          hijack_cursor = true;
          sync_root_with_cwd = true;
          update_focused_file = {
            enable = true;
            update_root = false;
          };
          view = {
            width = 40;
            preserve_window_proportions = true;
          };
          renderer = {
            root_folder_label = false;
            highlight_git = true;
            indent_markers.enable = true;
            icons.glyphs = {
              default = "󰈚";
              folder = {
                default = "";
                empty = "";
                empty_open = "";
                open = "";
                symlink = "";
              };
              git = { unmerged = ""; };
            };
          };
        };
      };

      tmux-navigator.enable = true;
    };

    keymaps = [
      # Telescope
      { mode = "n"; key = "<leader>ff"; action.__raw = ''function() require("telescope.builtin").find_files() end''; options.desc = "Telescope Find Files"; }
      { mode = "n"; key = "<leader>fw"; action.__raw = ''function() require("telescope.builtin").live_grep() end''; options.desc = "Telescope Live Grep"; }
      { mode = "n"; key = "<leader>fb"; action.__raw = ''function() require("telescope.builtin").buffers() end''; options.desc = "Telescope Buffers"; }
      { mode = "n"; key = "<leader>fh"; action.__raw = ''function() require("telescope.builtin").help_tags() end''; options.desc = "Telescope Help Tags"; }
      { mode = "n"; key = "<leader>ma"; action.__raw = ''function() require("telescope.builtin").marks() end''; options.desc = "Telescope Marks"; }
      { mode = "n"; key = "<leader>fz"; action.__raw = ''function() require("telescope.builtin").current_buffer_fuzzy_find() end''; options.desc = "Telescope Fuzzy Find"; }
      { mode = "n"; key = "<leader>ft"; action.__raw = ''function() require("config.worktree-picker").find_file_in_worktrees() end''; options.desc = "Find file in worktrees"; }
      { mode = "n"; key = "<leader>fr"; action = "<cmd>Telescope resume<cr>"; options.desc = "Resume last search"; }
      { mode = "n"; key = "<leader>fo"; action = "<cmd>Telescope oldfiles<cr>"; options.desc = "Recent files"; }
      { mode = "n"; key = "<leader>fd"; action = "<cmd>Telescope diagnostics<cr>"; options.desc = "Diagnostics"; }
      { mode = "n"; key = "<leader>fc"; action = "<cmd>Telescope commands<cr>"; options.desc = "Commands"; }
      { mode = "n"; key = "<leader>fK"; action = "<cmd>Telescope keymaps<cr>"; options.desc = "Keymaps"; }
      { mode = "n"; key = "<leader>fj"; action = "<cmd>Telescope jumplist<cr>"; options.desc = "Jumplist"; }
      { mode = "n"; key = "<leader>fs"; action = "<cmd>Telescope lsp_document_symbols<cr>"; options.desc = "Document symbols"; }
      { mode = "n"; key = "<leader>fS"; action = "<cmd>Telescope lsp_workspace_symbols<cr>"; options.desc = "Workspace symbols"; }
      { mode = "n"; key = "<leader>f*"; action = "<cmd>Telescope grep_string<cr>"; options.desc = "Grep word under cursor"; }
      { mode = "n"; key = "<leader>fGs"; action = "<cmd>Telescope git_status<cr>"; options.desc = "Git status"; }
      { mode = "n"; key = "<leader>fGf"; action = "<cmd>Telescope git_files<cr>"; options.desc = "Git files"; }
      { mode = "n"; key = "<leader>fGc"; action = "<cmd>Telescope git_commits<cr>"; options.desc = "Git commits"; }
      { mode = "n"; key = "<leader>fGb"; action = "<cmd>Telescope git_branches<cr>"; options.desc = "Git branches"; }

      # Flash
      { mode = [ "n" "x" "o" ]; key = "s"; action.__raw = ''function() require("flash").jump() end''; options.desc = "Flash"; }
      { mode = [ "n" "x" "o" ]; key = "S"; action.__raw = ''function() require("flash").treesitter() end''; options.desc = "Flash Treesitter"; }
      { mode = "o"; key = "r"; action.__raw = ''function() require("flash").remote() end''; options.desc = "Remote Flash"; }
      { mode = [ "o" "x" ]; key = "R"; action.__raw = ''function() require("flash").treesitter_search() end''; options.desc = "Treesitter Search"; }
      { mode = "c"; key = "<c-s>"; action.__raw = ''function() require("flash").toggle() end''; options.desc = "Toggle Flash Search"; }

      # Oil
      { mode = "n"; key = "-"; action = "<cmd>Oil<cr>"; options.desc = "Open parent directory"; }
      { mode = "n"; key = "<leader>eo"; action = "<cmd>Oil .<cr>"; options.desc = "Oil at cwd"; }
      { mode = "n"; key = "<leader>ep"; action.__raw = ''function() require("oil").open(vim.fn.expand("%:p:h")) end''; options.desc = "Oil parent of file"; }

      # NvimTree
      { mode = "n"; key = "<C-n>"; action = "<cmd>NvimTreeToggle<cr>"; options.desc = "Toggle file tree"; }
      { mode = "n"; key = "<leader>ee"; action = "<cmd>NvimTreeToggle<cr>"; options.desc = "Toggle file tree"; }
      { mode = "n"; key = "<leader>ef"; action = "<cmd>NvimTreeFindFile<cr>"; options.desc = "Find file in tree"; }
      { mode = "n"; key = "<leader>er"; action = "<cmd>NvimTreeRefresh<cr>"; options.desc = "Refresh tree"; }
      { mode = "n"; key = "<leader>ec"; action = "<cmd>NvimTreeCollapse<cr>"; options.desc = "Collapse tree"; }
    ];

    extraConfigLua = ''
      -- Telescope highlight links
      vim.api.nvim_set_hl(0, "TelescopeSelection", { link = "Visual" })
      vim.api.nvim_set_hl(0, "TelescopeSelectionCaret", { link = "CursorLineNr" })
      vim.api.nvim_set_hl(0, "TelescopePromptPrefix", { link = "Identifier" })
      vim.api.nvim_set_hl(0, "TelescopeMatching", { link = "Search" })
    '';
  };
}
