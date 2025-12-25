return {
	"nvimdev/lspsaga.nvim",
	config = function()
		require("lspsaga").setup({
			symbol_in_winbar = {
				folder_level = 3, -- Show 3 levels of folders (default is 1)
			},
		})
	end,
	dependencies = {
		"nvim-treesitter/nvim-treesitter", -- optional
		"nvim-tree/nvim-web-devicons", -- optional
	},
	keys = {
		{ "<leader>cf", "<cmd>Lspsaga finder<cr>", desc = "LSP finder" },
		{ "<leader>cp", "<cmd>Lspsaga peek_definition<cr>", desc = "Peek definition" },
		{ "<leader>cP", "<cmd>Lspsaga peek_type_definition<cr>", desc = "Peek type definition" },
		{ "<leader>co", "<cmd>Lspsaga outline<cr>", desc = "Toggle outline" },
		{ "<leader>ci", "<cmd>Lspsaga incoming_calls<cr>", desc = "Incoming calls" },
		{ "<leader>cO", "<cmd>Lspsaga outgoing_calls<cr>", desc = "Outgoing calls" },
		{ "<leader>ch", "<cmd>Lspsaga hover_doc<cr>", desc = "Hover doc" },
		{ "<leader>ca", "<cmd>Lspsaga code_action<cr>", desc = "Code action", mode = { "n", "v" } },
	},
}
