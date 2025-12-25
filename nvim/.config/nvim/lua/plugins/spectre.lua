return {
	"nvim-pack/nvim-spectre",
	dependencies = { "nvim-lua/plenary.nvim" },
	cmd = "Spectre",
	keys = {
		{
			"<leader>sr",
			function()
				require("spectre").open()
			end,
			desc = "Search and replace",
		},
		{
			"<leader>sw",
			function()
				require("spectre").open_visual({ select_word = true })
			end,
			desc = "Search word under cursor",
			mode = "n",
		},
		{
			"<leader>sw",
			function()
				require("spectre").open_visual()
			end,
			mode = "v",
			desc = "Search selection",
		},
		{
			"<leader>sf",
			function()
				require("spectre").open_file_search({ select_word = true })
			end,
			desc = "Search in current file",
		},
		{
			"<leader>sR",
			function()
				require("spectre").replace()
			end,
			desc = "Replace all",
		},
		{
			"<leader>st",
			function()
				require("spectre").toggle_live_update()
			end,
			desc = "Toggle live update",
		},
	},
	opts = {
		open_cmd = "noswapfile vnew",
	},
}
