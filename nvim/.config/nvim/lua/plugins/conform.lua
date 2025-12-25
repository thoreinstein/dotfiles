return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>rf",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			mode = { "n", "v" },
			desc = "Format buffer",
		},
		{
			"<leader>rF",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			mode = "v",
			desc = "Format selection",
		},
		{
			"<leader>rt",
			function()
				vim.g.disable_autoformat = not vim.g.disable_autoformat
				vim.notify("Format on save: " .. (vim.g.disable_autoformat and "OFF" or "ON"))
			end,
			desc = "Toggle format on save",
		},
	},
	opts = {
		formatters_by_ft = {
			css = { "prettier" },
			go = { "goimports", "gofmt" },
			graphql = { "prettier" },
			handlebars = { "prettier" },
			html = { "prettier" },
			javascript = { "prettier" },
			javascriptreact = { "prettier" },
			json = { "prettier" },
			jsonc = { "prettier" },
			less = { "prettier" },
			lua = { "stylua" },
			markdown = { "prettier" },
			python = { "isort", "black" },
			rust = { "rustfmt" },
			scss = { "prettier" },
			sh = { "shfmt" },
			typescript = { "prettier" },
			typescriptreact = { "prettier" },
			vue = { "prettier" },
			-- yaml = { "prettier" },
		},
		format_on_save = function(bufnr)
			if vim.g.disable_autoformat then
				return
			end
			local filepath = vim.api.nvim_buf_get_name(bufnr)
			if filepath:match("templates/.*%.ya?ml$") then
				return false
			end
			return {
				timeout_ms = 500,
				lsp_fallback = true,
			}
		end,
	},
}
