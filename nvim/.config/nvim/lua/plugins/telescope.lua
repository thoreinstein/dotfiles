return {
	"nvim-telescope/telescope.nvim",
	dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
	cmd = "Telescope",
	opts = {
		defaults = {
			prompt_prefix = "   ",
			selection_caret = " ",
			entry_prefix = " ",
			sorting_strategy = "ascending",
			layout_config = {
				horizontal = {
					prompt_position = "top",
					preview_width = 0.55,
				},
				width = 0.87,
				height = 0.80,
			},
			mappings = {
				n = { ["q"] = require("telescope.actions").close },
			},
		},

		extensions_list = {},
		extensions = {},
	},
	config = function(_, opts)
		require("telescope").setup(opts)

		-- Link telescope highlights to theme groups for consistency
		-- Colors adapt automatically when switching themes
		vim.api.nvim_set_hl(0, "TelescopeSelection", { link = "Visual" })
		vim.api.nvim_set_hl(0, "TelescopeSelectionCaret", { link = "CursorLineNr" })
		vim.api.nvim_set_hl(0, "TelescopePromptPrefix", { link = "Identifier" })
		vim.api.nvim_set_hl(0, "TelescopeMatching", { link = "Search" })
	end,
	keys = function()
		local builtin = require("telescope.builtin")
		return {
			{
				"<leader>ff",
				function()
					builtin.find_files()
				end,
				desc = "Telescope Find Files",
			},
			{
				"<leader>fw",
				function()
					builtin.live_grep()
				end,
				desc = "Telescope Live Grep",
			},
			{
				"<leader>fb",
				function()
					builtin.buffers()
				end,
				desc = "Telescope Buffers",
			},
			{
				"<leader>fh",
				function()
					builtin.help_tags()
				end,
				desc = "Telescope Help Tags",
			},
			{
				"<leader>ma",
				function()
					builtin.marks()
				end,
				desc = "Telescope Marks",
			},
			{
				"<leader>fz",
				function()
					builtin.current_buffer_fuzzy_find()
				end,
				desc = "Telescope Fuzzy Find",
			},
			{
				"<leader>ft",
				function()
					require("config.worktree-picker").find_file_in_worktrees()
				end,
				desc = "Find file in worktrees",
			},
			{ "<leader>fr", "<cmd>Telescope resume<cr>", desc = "Resume last search" },
			{ "<leader>fo", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
			{ "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
			{ "<leader>fc", "<cmd>Telescope commands<cr>", desc = "Commands" },
			{ "<leader>fK", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
			{ "<leader>fj", "<cmd>Telescope jumplist<cr>", desc = "Jumplist" },
			{ "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document symbols" },
			{ "<leader>fS", "<cmd>Telescope lsp_workspace_symbols<cr>", desc = "Workspace symbols" },
			{ "<leader>f*", "<cmd>Telescope grep_string<cr>", desc = "Grep word under cursor" },
			{ "<leader>fGs", "<cmd>Telescope git_status<cr>", desc = "Git status" },
			{ "<leader>fGf", "<cmd>Telescope git_files<cr>", desc = "Git files" },
			{ "<leader>fGc", "<cmd>Telescope git_commits<cr>", desc = "Git commits" },
			{ "<leader>fGb", "<cmd>Telescope git_branches<cr>", desc = "Git branches" },
		}
	end,
}
