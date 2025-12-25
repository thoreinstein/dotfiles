return {
	"WhoIsSethDaniel/mason-tool-installer.nvim",
	dependencies = { "mason.nvim" },
	config = function()
		require("mason-tool-installer").setup({
			ensure_installed = {
				-- Go
				-- "gopls",
				"gofumpt",
				"goimports",
				"golangci-lint",
				"delve",

				-- Lua
				"lua-language-server",
				"stylua",

				-- Python
				"pyright",
				"black",
				"isort",
				"flake8",

				-- TypeScript/JavaScript
				"typescript-language-server",
				"prettierd",
				"eslint_d",

				-- Other
				"rust-analyzer",
				"taplo", -- TOML
				"yamlfmt",
				"shfmt",
				"shellcheck",
				"markdownlint",
			},
			auto_update = false,
			run_on_start = true,
		})
	end,
}
