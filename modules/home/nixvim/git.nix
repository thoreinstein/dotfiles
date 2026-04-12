{ pkgs, ... }:
{
  programs.nixvim = {
    plugins = {
      gitsigns = {
        enable = true;
        settings = {
          signs = {
            add = { text = "│"; };
            change = { text = "│"; };
            delete = { text = "_"; };
            topdelete = { text = "‾"; };
            changedelete = { text = "~"; };
            untracked = { text = "┆"; };
          };
          signs_staged = {
            add = { text = "│"; };
            change = { text = "│"; };
            delete = { text = "_"; };
            topdelete = { text = "‾"; };
            changedelete = { text = "~"; };
          };
          current_line_blame = true;
          current_line_blame_opts = {
            virt_text = true;
            virt_text_pos = "eol";
            delay = 500;
            ignore_whitespace = false;
          };
          current_line_blame_formatter = "<author>, <author_time:%R> - <summary>";
          preview_config = {
            border = "rounded";
            style = "minimal";
            relative = "cursor";
            row = 0;
            col = 1;
          };
          on_attach = {
            __raw = ''
              function(bufnr)
                local gs = package.loaded.gitsigns
                local function map(mode, l, r, opts)
                  opts = opts or {}
                  opts.buffer = bufnr
                  vim.keymap.set(mode, l, r, opts)
                end

                map("n", "]h", function()
                  if vim.wo.diff then
                    vim.cmd.normal({ "]c", bang = true })
                  else
                    gs.nav_hunk("next")
                  end
                end, { desc = "Next hunk" })

                map("n", "[h", function()
                  if vim.wo.diff then
                    vim.cmd.normal({ "[c", bang = true })
                  else
                    gs.nav_hunk("prev")
                  end
                end, { desc = "Previous hunk" })

                map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
                map("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
                map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
                map("n", "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
                map("n", "<leader>hS", gs.stage_buffer, { desc = "Stage buffer" })
                map("n", "<leader>hR", gs.reset_buffer, { desc = "Reset buffer" })

                map("v", "<leader>hs", function()
                  gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end, { desc = "Stage selected lines" })
                map("v", "<leader>hr", function()
                  gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end, { desc = "Reset selected lines" })

                map("n", "<leader>hb", function()
                  gs.blame_line({ full = true })
                end, { desc = "Blame line" })
                map("n", "<leader>hB", gs.toggle_current_line_blame, { desc = "Toggle line blame" })

                map("n", "<leader>hd", gs.diffthis, { desc = "Diff this file" })

                map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select hunk" })
              end
            '';
          };
        };
      };

      neogit = {
        enable = true;
        settings = {
          graph_style = "unicode";
          integrations = {
            diffview = true;
            telescope = true;
          };
          kind = "tab";
          signs = {
            hunk = [ "" "" ];
            item = [ "" "" ];
            section = [ "" "" ];
          };
          disable_line_numbers = true;
          auto_refresh = true;
          status = {
            recent_commit_count = 10;
          };
          commit_editor = {
            kind = "split";
          };
          popup = {
            kind = "split";
          };
        };
      };

      diffview = {
        enable = true;
      };

      fugitive.enable = true;

      git-conflict = {
        enable = true;
      };

      octo = {
        enable = true;
        settings = {
          enable_builtin = true;
          default_to_projects_v2 = true;
        };
      };
    };

    keymaps = [
      # Neogit
      { mode = "n"; key = "<leader>gg"; action.__raw = ''function() require("neogit").open() end''; options.desc = "Neogit status"; }
      { mode = "n"; key = "<leader>gc"; action.__raw = ''function() require("neogit").open({ "commit" }) end''; options.desc = "Neogit commit"; }
      { mode = "n"; key = "<leader>gP"; action.__raw = ''function() require("neogit").open({ "push" }) end''; options.desc = "Neogit push"; }
      { mode = "n"; key = "<leader>gF"; action.__raw = ''function() require("neogit").open({ "pull" }) end''; options.desc = "Neogit pull"; }
      { mode = "n"; key = "<leader>gB"; action.__raw = ''function() require("neogit").open({ "branch" }) end''; options.desc = "Neogit branch"; }
      { mode = "n"; key = "<leader>gL"; action.__raw = ''function() require("neogit").open({ "log" }) end''; options.desc = "Neogit log"; }

      # Diffview
      { mode = "n"; key = "<leader>gd"; action = "<cmd>DiffviewOpen<cr>"; options.desc = "Diff view (working tree vs HEAD)"; }
      { mode = "n"; key = "<leader>gs"; action = "<cmd>DiffviewOpen --staged<cr>"; options.desc = "Diff view (staged vs HEAD)"; }
      { mode = "n"; key = "<leader>gD"; action = "<cmd>DiffviewOpen -- %<cr>"; options.desc = "Diff current file vs HEAD"; }
      { mode = "n"; key = "<leader>gh"; action = "<cmd>DiffviewFileHistory %<cr>"; options.desc = "File history (current file)"; }
      { mode = "n"; key = "<leader>gH"; action = "<cmd>DiffviewFileHistory<cr>"; options.desc = "File history (repo)"; }

      # Fugitive
      { mode = "n"; key = "<leader>gf"; action = "<cmd>Git<cr>"; options.desc = "Fugitive (Git Status)"; }
      { mode = "n"; key = "<leader>gV"; action = "<cmd>Gvdiffsplit!<cr>"; options.desc = "Fugitive 3-way Merge"; }

      # Octo
      { mode = "n"; key = "<leader>oPr"; action = "<cmd>Octo pr checkout<cr>"; options.desc = "Checkout PR"; }
      { mode = "n"; key = "<leader>oPo"; action = "<cmd>Octo pr browser<cr>"; options.desc = "Open PR in browser"; }
      { mode = "n"; key = "<leader>oPa"; action = "<cmd>Octo review submit approve<cr>"; options.desc = "Approve PR"; }
      { mode = "n"; key = "<leader>oPc"; action = "<cmd>Octo comment add<cr>"; options.desc = "Add comment"; }
      { mode = "n"; key = "<leader>oPm"; action = "<cmd>Octo pr merge<cr>"; options.desc = "Merge PR"; }
      { mode = "n"; key = "<leader>oPl"; action = "<cmd>Octo pr list<cr>"; options.desc = "List PRs"; }
      { mode = "n"; key = "<leader>oIl"; action = "<cmd>Octo issue list<cr>"; options.desc = "List issues"; }
      { mode = "n"; key = "<leader>oIc"; action = "<cmd>Octo issue create<cr>"; options.desc = "Create issue"; }
      { mode = "n"; key = "<leader>oIb"; action = "<cmd>Octo issue browser<cr>"; options.desc = "Open issue in browser"; }
    ];

    extraConfigLua = ''
      -- Fugitive conflict resolution keymaps
      vim.keymap.set("n", "g2", "<cmd>diffget //2<cr>", { desc = "Git: Get from Target (Left/Buf 2)" })
      vim.keymap.set("n", "g3", "<cmd>diffget //3<cr>", { desc = "Git: Get from Merge (Right/Buf 3)" })

      -- Diffview keymaps and settings
      require("diffview").setup({
        view = {
          default = { layout = "diff2_horizontal", winbar_info = true },
          merge_tool = { layout = "diff3_horizontal", disable_diagnostics = true, winbar_info = true },
          file_history = { layout = "diff2_horizontal", winbar_info = true },
        },
        file_panel = {
          listing_style = "tree",
          tree_options = { flatten_dirs = true, folder_statuses = "only_folded" },
          win_config = { position = "left", width = 35 },
        },
        file_history_panel = {
          log_options = {
            git = {
              single_file = { diff_merges = "combined" },
              multi_file = { diff_merges = "first-parent" },
            },
          },
          win_config = { position = "bottom", height = 16 },
        },
        keymaps = {
          disable_defaults = false,
          view = {
            { "n", "]d", function() require("diffview.actions").select_next_entry() end, { desc = "Next file in diff" } },
            { "n", "[d", function() require("diffview.actions").select_prev_entry() end, { desc = "Previous file in diff" } },
            { "n", "]c", function() require("diffview.actions").next_conflict() end, { desc = "Next change/conflict" } },
            { "n", "[c", function() require("diffview.actions").prev_conflict() end, { desc = "Previous change/conflict" } },
            { "n", "<Tab>", function() require("diffview.actions").toggle_files() end, { desc = "Toggle file panel" } },
            { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
          },
          file_panel = {
            { "n", "]d", function() require("diffview.actions").select_next_entry() end, { desc = "Next file" } },
            { "n", "[d", function() require("diffview.actions").select_prev_entry() end, { desc = "Previous file" } },
            { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
          },
          file_history_panel = {
            { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
          },
        },
        hooks = {
          diff_buf_read = function(bufnr)
            vim.opt_local.wrap = false
            vim.opt_local.list = false
          end,
        },
      })
    '';
  };
}
