-- ============================================================================
-- Diffview.nvim - GitHub-style side-by-side diff UI
-- ============================================================================
-- Provides a full-featured diff interface similar to GitHub's PR/file diffs.
--
-- KEYBINDINGS (all under <leader>g prefix for git operations):
--   <leader>gd  - Open diff view (all changed files vs HEAD)
--   <leader>gD  - Open diff view for current file only
--   <leader>gs  - Open diff view of staged changes vs HEAD
--   <leader>gh  - Open file history (current file)
--   <leader>gH  - Open file history (entire repo)
--   <leader>gc  - Close diff view and return to previous layout
--
-- NAVIGATION (within diff view):
--   ]d / [d     - Next/previous file in the file panel
--   ]c / [c     - Next/previous hunk/change within a file
--   <Tab>       - Toggle file panel focus
--   <CR>        - Open file / select entry
--   gf          - Go to file (opens in new tab)
--   X           - Restore file to original state (discard changes)
--   -           - Toggle staging of entry
--   S           - Stage all entries
--   U           - Unstage all entries
--
-- From Neogit, pressing 'd' on a file will open it in diffview.
-- ============================================================================

return {
	"sindrets/diffview.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles" },
	keys = {
		-- Project diff views
		{
			"<leader>gd",
			"<cmd>DiffviewOpen<cr>",
			desc = "Diff view (working tree vs HEAD)",
		},
		{
			"<leader>gs",
			"<cmd>DiffviewOpen --staged<cr>",
			desc = "Diff view (staged vs HEAD)",
		},
		-- Current file diff
		{
			"<leader>gD",
			"<cmd>DiffviewOpen -- %<cr>",
			desc = "Diff current file vs HEAD",
		},
		-- File history
		{
			"<leader>gh",
			"<cmd>DiffviewFileHistory %<cr>",
			desc = "File history (current file)",
		},
		{
			"<leader>gH",
			"<cmd>DiffviewFileHistory<cr>",
			desc = "File history (repo)",
		},
		-- Close diff view
		{
			"<leader>gc",
			"<cmd>DiffviewClose<cr>",
			desc = "Close diff view",
		},
	},
	opts = {
		-- Use side-by-side diff layout (GitHub-style)
		view = {
			default = {
				layout = "diff2_horizontal",
				winbar_info = true,
			},
			merge_tool = {
				layout = "diff3_horizontal",
				disable_diagnostics = true,
				winbar_info = true,
			},
			file_history = {
				layout = "diff2_horizontal",
				winbar_info = true,
			},
		},
		-- File panel on the left (like GitHub's file list)
		file_panel = {
			listing_style = "tree",
			tree_options = {
				flatten_dirs = true,
				folder_statuses = "only_folded",
			},
			win_config = {
				position = "left",
				width = 35,
			},
		},
		-- Show file stats in the file panel
		file_history_panel = {
			log_options = {
				git = {
					single_file = {
						diff_merges = "combined",
					},
					multi_file = {
						diff_merges = "first-parent",
					},
				},
			},
			win_config = {
				position = "bottom",
				height = 16,
			},
		},
		-- Keymaps within diffview
		keymaps = {
			disable_defaults = false,
			view = {
				-- Navigate between files in the diff
				{
					"n",
					"]d",
					function()
						require("diffview.actions").select_next_entry()
					end,
					{ desc = "Next file in diff" },
				},
				{
					"n",
					"[d",
					function()
						require("diffview.actions").select_prev_entry()
					end,
					{ desc = "Previous file in diff" },
				},
				-- Navigate between hunks/changes
				{
					"n",
					"]c",
					function()
						require("diffview.actions").next_conflict()
					end,
					{ desc = "Next change/conflict" },
				},
				{
					"n",
					"[c",
					function()
						require("diffview.actions").prev_conflict()
					end,
					{ desc = "Previous change/conflict" },
				},
				-- Toggle file panel
				{
					"n",
					"<Tab>",
					function()
						require("diffview.actions").toggle_files()
					end,
					{ desc = "Toggle file panel" },
				},
				-- Close diffview with q
				{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
			},
			file_panel = {
				-- Navigate files
				{
					"n",
					"]d",
					function()
						require("diffview.actions").select_next_entry()
					end,
					{ desc = "Next file" },
				},
				{
					"n",
					"[d",
					function()
						require("diffview.actions").select_prev_entry()
					end,
					{ desc = "Previous file" },
				},
				-- Close with q
				{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
			},
			file_history_panel = {
				{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
			},
		},
		hooks = {
			-- Improve diff highlighting to be more readable
			diff_buf_read = function(bufnr)
				-- Disable certain features in diff buffers for cleaner view
				vim.opt_local.wrap = false
				vim.opt_local.list = false
			end,
		},
	},
}
