return {
	"petertriho/nvim-scrollbar",
	event = "BufReadPost",
	opts = {
		show_in_active_only = true,
		handle = {
			blend = 0,
		},
		marks = {
			Search = { color = "#ff9e64" },
			Error = { color = "#db4b4b" },
			Warn = { color = "#e0af68" },
			Info = { color = "#0db9d7" },
			Hint = { color = "#1abc9c" },
			Misc = { color = "#9d7cd8" },
		},
		handlers = {
			cursor = true,
			diagnostic = true,
			gitsigns = true,
			search = false,
		},
	},
	config = function(_, opts)
		require("scrollbar").setup(opts)
		require("scrollbar.handlers.gitsigns").setup()
	end,
}
