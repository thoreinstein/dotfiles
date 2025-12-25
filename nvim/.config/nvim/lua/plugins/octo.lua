return {
	"pwntester/octo.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
		"nvim-tree/nvim-web-devicons",
	},
	cmd = "Octo",
	keys = {
		{ "<leader>oPr", "<cmd>Octo pr checkout<cr>", desc = "Checkout PR" },
		{ "<leader>oPo", "<cmd>Octo pr browser<cr>", desc = "Open PR in browser" },
		{ "<leader>oPa", "<cmd>Octo review submit approve<cr>", desc = "Approve PR" },
		{ "<leader>oPc", "<cmd>Octo comment add<cr>", desc = "Add comment" },
		{ "<leader>oPm", "<cmd>Octo pr merge<cr>", desc = "Merge PR" },
		{ "<leader>oPl", "<cmd>Octo pr list<cr>", desc = "List PRs" },
		{ "<leader>oIl", "<cmd>Octo issue list<cr>", desc = "List issues" },
		{ "<leader>oIc", "<cmd>Octo issue create<cr>", desc = "Create issue" },
		{ "<leader>oIb", "<cmd>Octo issue browser<cr>", desc = "Open issue in browser" },
	},
	opts = {
		enable_builtin = true,
		default_to_projects_v2 = true,
	},
}
