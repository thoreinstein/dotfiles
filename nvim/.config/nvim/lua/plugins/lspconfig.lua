vim.api.nvim_create_autocmd("BufRead", {
	pattern = "*/templates/*.yaml",
	callback = function()
		vim.bo.filetype = "helm"
	end,
})

return {
	"neovim/nvim-lspconfig",
	config = function()
		local M = {}
		local map = vim.keymap.set

		M.on_attach = function(_, bufnr)
			local function opts(desc)
				return { buffer = bufnr, desc = "LSP " .. desc }
			end
			map("n", "gD", vim.lsp.buf.declaration, opts("Go to declaration"))
			map("n", "gd", vim.lsp.buf.definition, opts("Go to definition"))
			map("n", "gi", vim.lsp.buf.implementation, opts("Go to implementation"))
			map("n", "<leader>k", vim.lsp.buf.signature_help, opts("Signature help"))
			map("n", "<leader>K", vim.lsp.buf.hover, opts("Hover"))
			map("n", "<leader>D", vim.lsp.buf.type_definition, opts("Go to type definition"))
			map("n", "<leader>rn", vim.lsp.buf.rename, opts("Rename"))
			map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts("Code action"))
			map("n", "gr", vim.lsp.buf.references, opts("References"))
			map("n", "<leader>e", vim.diagnostic.open_float, opts("Show diagnostic"))
			map("n", "<leader>q", vim.diagnostic.setloclist, opts("Diagnostic loclist"))
			map("n", "[d", vim.diagnostic.goto_prev, { buffer = bufnr, desc = "Prev diagnostic" })
			map("n", "]d", vim.diagnostic.goto_next, { buffer = bufnr, desc = "Next diagnostic" })
			map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, { buffer = bufnr, desc = "Add workspace folder" })
			map(
				"n",
				"<leader>wr",
				vim.lsp.buf.remove_workspace_folder,
				{ buffer = bufnr, desc = "Remove workspace folder" }
			)
			map("n", "<leader>wl", function()
				print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
			end, { buffer = bufnr, desc = "List workspace folders" })
		end

		M.on_init = function(client, _)
			if client.supports_method("textDocument/semanticTokens") then
				client.server_capabilities.semanticTokensProvider = nil
			end
		end

		M.capabilities = require("blink.cmp").get_lsp_capabilities()

		M.defaults = function()
			vim.diagnostic.config({
				virtual_text = false,
				signs = true,
				underline = true,
				update_in_insert = false,
				severity_sort = true,
			})

			local signs = { Error = "󰅚 ", Warn = "󰀪 ", Hint = "󰌶 ", Info = " " }
			for type, icon in pairs(signs) do
				local hl = "DiagnosticSign" .. type
				vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
			end

			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					if client then
						M.on_attach(client, args.buf)
					end
				end,
			})

			local lua_lsp_settings = {
				Lua = {
					workspace = {
						library = {
							vim.fn.expand("$VIMRUNTIME/lua"),
							vim.fn.stdpath("data") .. "/lazy/lazy.nvim/lua/lazy",
							"${3rd}/luv/library",
						},
					},
				},
			}

			local gopls_settings = {
				gopls = {
					completeUnimported = true,
					usePlaceholders = true,
					buildFlags = {},
					analyses = {
						unusedparams = true,
						unreachable = true,
						fillstruct = true,
						nonewvars = true,
						undeclaredname = true,
						unusedwrite = true,
						unusedvariable = true,
						ST1000 = false,
					},
					staticcheck = true,
					gofumpt = true,
					codelenses = {
						gc_details = false,
						generate = true,
						regenerate_cgo = true,
						run_govulncheck = true,
						test = true,
						tidy = true,
						upgrade_dependency = true,
						vendor = true,
					},
					hints = {
						assignVariableTypes = true,
						compositeLiteralFields = true,
						compositeLiteralTypes = true,
						constantValues = true,
						functionTypeParameters = true,
						parameterNames = true,
						rangeVariableTypes = true,
					},
				},
			}

			if vim.lsp.config then
				vim.lsp.config("*", { capabilities = M.capabilities, on_init = M.on_init })
				vim.lsp.config("lua_ls", { settings = lua_lsp_settings })
				vim.lsp.config("gopls", { settings = gopls_settings })
				vim.lsp.enable("lua_ls")
				vim.lsp.enable("gopls")
			else
				require("lspconfig").lua_ls.setup({
					capabilities = M.capabilities,
					on_init = M.on_init,
					settings = lua_lsp_settings,
				})

				require("lspconfig").gopls.setup({
					capabilities = M.capabilities,
					on_init = M.on_init,
					settings = gopls_settings,
				})
			end
		end

		M.defaults()
	end,
}
