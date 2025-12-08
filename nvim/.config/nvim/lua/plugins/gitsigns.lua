-- ============================================================================
-- Gitsigns.nvim - Inline git signs and hunk operations
-- ============================================================================
-- Shows git status in the sign column and provides quick hunk operations.
-- Use this for quick inline checks; use diffview for full-page 2-way diffs.
--
-- SIGN COLUMN:
--   │  - Added line
--   │  - Changed line
--   _  - Deleted line (shown at line above deletion)
--
-- KEYBINDINGS (hunk navigation - works everywhere):
--   ]h          - Jump to next hunk
--   [h          - Jump to previous hunk
--
-- KEYBINDINGS (hunk operations - <leader>h prefix):
--   <leader>hp  - Preview hunk in floating window
--   <leader>hs  - Stage hunk
--   <leader>hu  - Undo stage hunk (unstage)
--   <leader>hr  - Reset hunk (discard changes)
--   <leader>hS  - Stage entire buffer
--   <leader>hR  - Reset entire buffer
--   <leader>hb  - Blame line (show who changed it)
--   <leader>hB  - Toggle line blame (persistent)
--   <leader>hd  - Diff this file (opens in diffview if available)
--
-- VISUAL MODE (select lines then use):
--   <leader>hs  - Stage selected lines
--   <leader>hr  - Reset selected lines
--
-- TEXT OBJECT:
--   ih          - Inner hunk (use with operators like d, y, c)
-- ============================================================================

return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    -- Sign column symbols (subtle but visible)
    signs = {
      add = { text = "│" },
      change = { text = "│" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "~" },
      untracked = { text = "┆" },
    },
    signs_staged = {
      add = { text = "│" },
      change = { text = "│" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "~" },
    },
    -- Show blame for current line inline
    current_line_blame = true,
    current_line_blame_opts = {
      virt_text = true,
      virt_text_pos = "eol",
      delay = 500,
      ignore_whitespace = false,
    },
    current_line_blame_formatter = "<author>, <author_time:%R> - <summary>",
    -- Preview window settings
    preview_config = {
      border = "rounded",
      style = "minimal",
      relative = "cursor",
      row = 0,
      col = 1,
    },
    -- Keymaps defined via on_attach for buffer-local bindings
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation between hunks
      map("n", "]h", function()
        if vim.wo.diff then
          vim.cmd.normal { "]c", bang = true }
        else
          gs.nav_hunk "next"
        end
      end, { desc = "Next hunk" })

      map("n", "[h", function()
        if vim.wo.diff then
          vim.cmd.normal { "[c", bang = true }
        else
          gs.nav_hunk "prev"
        end
      end, { desc = "Previous hunk" })

      -- Hunk operations (normal mode)
      map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
      map("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
      map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
      map("n", "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
      map("n", "<leader>hS", gs.stage_buffer, { desc = "Stage buffer" })
      map("n", "<leader>hR", gs.reset_buffer, { desc = "Reset buffer" })

      -- Hunk operations (visual mode - for selected lines)
      map("v", "<leader>hs", function()
        gs.stage_hunk { vim.fn.line ".", vim.fn.line "v" }
      end, { desc = "Stage selected lines" })
      map("v", "<leader>hr", function()
        gs.reset_hunk { vim.fn.line ".", vim.fn.line "v" }
      end, { desc = "Reset selected lines" })

      -- Blame
      map("n", "<leader>hb", function()
        gs.blame_line { full = true }
      end, { desc = "Blame line" })
      map("n", "<leader>hB", gs.toggle_current_line_blame, { desc = "Toggle line blame" })

      -- Diff (integrates with diffview)
      map("n", "<leader>hd", gs.diffthis, { desc = "Diff this file" })

      -- Text object for hunks (e.g., vih to select hunk, dih to delete)
      map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select hunk" })
    end,
  },
}
