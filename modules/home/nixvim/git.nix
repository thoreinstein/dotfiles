_: {
  programs.nixvim = {
    plugins = {
      gitsigns = {
        enable = true;
        settings = {
          signs = {
            add = {
              text = "│";
            };
            change = {
              text = "│";
            };
            delete = {
              text = "_";
            };
            topdelete = {
              text = "‾";
            };
            changedelete = {
              text = "~";
            };
            untracked = {
              text = "┆";
            };
          };
          signs_staged = {
            add = {
              text = "│";
            };
            change = {
              text = "│";
            };
            delete = {
              text = "_";
            };
            topdelete = {
              text = "‾";
            };
            changedelete = {
              text = "~";
            };
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

      diffview = {
        enable = true;
      };

      fugitive.enable = true;
    };

    keymaps = [
      # Diffview
      {
        mode = "n";
        key = "<leader>gd";
        action = "<cmd>DiffviewOpen<cr>";
        options.desc = "Diff view (working tree vs HEAD)";
      }
      {
        mode = "n";
        key = "<leader>gs";
        action = "<cmd>DiffviewOpen --staged<cr>";
        options.desc = "Diff view (staged vs HEAD)";
      }
      {
        mode = "n";
        key = "<leader>gD";
        action = "<cmd>DiffviewOpen -- %<cr>";
        options.desc = "Diff current file vs HEAD";
      }
      {
        mode = "n";
        key = "<leader>gh";
        action = "<cmd>DiffviewFileHistory %<cr>";
        options.desc = "File history (current file)";
      }
      {
        mode = "n";
        key = "<leader>gH";
        action = "<cmd>DiffviewFileHistory<cr>";
        options.desc = "File history (repo)";
      }

      # PR review: diff the checked-out PR branch against its merge-base
      # with main. Fetch the PR first, e.g. `gh pr checkout <n>`.
      {
        mode = "n";
        key = "<leader>gP";
        action = "<cmd>DiffviewOpen origin/main...HEAD<cr>";
        options.desc = "Diff vs origin/main (PR review)";
      }

      # Fugitive
      {
        mode = "n";
        key = "<leader>gf";
        action = "<cmd>Git<cr>";
        options.desc = "Fugitive (Git Status)";
      }
      {
        mode = "n";
        key = "<leader>gV";
        action = "<cmd>Gvdiffsplit!<cr>";
        options.desc = "Fugitive 3-way Merge";
      }
    ];

    extraConfigLua = ''
      -- Fugitive conflict resolution keymaps
      vim.keymap.set("n", "g2", "<cmd>diffget //2<cr>", { desc = "Git: Get from Target (Left/Buf 2)" })
      vim.keymap.set("n", "g3", "<cmd>diffget //3<cr>", { desc = "Git: Get from Merge (Right/Buf 3)" })
    '';
  };
}
