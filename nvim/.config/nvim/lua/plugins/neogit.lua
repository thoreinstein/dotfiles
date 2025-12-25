-- ============================================================================
-- Neogit - Git interface (like Magit for Emacs)
-- ============================================================================
-- Full git UI for staging, committing, pushing, pulling, etc.
-- Integrates with diffview.nvim for side-by-side diffs.
--
-- KEYBINDINGS:
--   <leader>gg  - Open Neogit status
--
-- WITHIN NEOGIT:
--   s           - Stage file/hunk under cursor
--   u           - Unstage file/hunk under cursor
--   c           - Open commit popup
--   p           - Open push popup
--   P           - Open pull popup
--   d           - Open diff for file (uses diffview.nvim)
--   <Tab>       - Toggle diff inline / expand section
--   <CR>        - Open file
--   q           - Close Neogit
--   ?           - Show help with all keybindings
--
-- Pressing 'd' on any file in Neogit will open it in diffview for
-- a full GitHub-style side-by-side diff experience.
-- ============================================================================

return {
	"NeogitOrg/neogit",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"sindrets/diffview.nvim",
		"nvim-telescope/telescope.nvim",
	},
	cmd = "Neogit",
	keys = {
		{
			"<leader>gg",
			function()
				require("neogit").open()
			end,
			desc = "Neogit status",
		},
		{
			"<leader>gc",
			function()
				require("neogit").open({ "commit" })
			end,
			desc = "Neogit commit",
		},
		{
			"<leader>gP",
			function()
				require("neogit").open({ "push" })
			end,
			desc = "Neogit push",
		},
		{
			"<leader>gF",
			function()
				require("neogit").open({ "pull" })
			end,
			desc = "Neogit pull",
		},
		{
			"<leader>gB",
			function()
				require("neogit").open({ "branch" })
			end,
			desc = "Neogit branch",
		},
		{
			"<leader>gL",
			function()
				require("neogit").open({ "log" })
			end,
			desc = "Neogit log",
		},
	},
	opts = {
		-- Use unicode for prettier graph
		graph_style = "unicode",
		-- Integrate with diffview for side-by-side diffs
		integrations = {
			diffview = true,
			telescope = true,
		},
		-- Open in current window rather than split
		kind = "tab",
		-- Sign column signs
		signs = {
			hunk = { "", "" },
			item = { "", "" },
			section = { "", "" },
		},
		-- Disable line numbers in Neogit buffers for cleaner UI
		disable_line_numbers = true,
		-- Automatically refresh when files change
		auto_refresh = true,
		-- Show recent commits in status
		status = {
			recent_commit_count = 10,
		},
		-- Commit editor settings
		commit_editor = {
			kind = "split",
		},
		-- Popup configuration
		popup = {
			kind = "split",
		},
	},
}
