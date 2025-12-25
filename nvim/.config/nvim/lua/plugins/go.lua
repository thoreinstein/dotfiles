return {
	"ray-x/go.nvim",
	dependencies = {
		"ray-x/guihua.lua",
		"neovim/nvim-lspconfig",
		"nvim-treesitter/nvim-treesitter",
	},
	config = function()
		require("go").setup({
			-- Disable auto format since we use conform.nvim
			lsp_cfg = {
				settings = {
					gopls = {
						buildFlags = {}, -- Project-specific flags go in .envrc or project-local .nvim.lua
						analyses = {
							unusedparams = true,
						},
						staticcheck = true,
						gofumpt = true,
					},
				},
			},
			lsp_keymaps = false, -- Use global LSP keymaps
			fmt_on_save = false, -- We use conform.nvim
			lsp_inlay_hints = {
				enable = true,
			},
			trouble = true, -- Enable trouble.nvim integration
			dap_debug = true, -- Enable dap debug support
			test_runner = "ginkgo", -- go, richgo, dlv, ginkgo
			run_in_floaterm = false, -- Use floaterm for running commands
			icons = { breakpoint = "🔴", currentpos = "🔶" },
		})
	end,
	event = { "CmdlineEnter" },
	ft = { "go", "gomod" },
	build = ':lua require("go.install").update_all_sync()',
}
