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

    -- export on_attach & capabilities
    M.on_attach = function(_, bufnr)
      local function opts(desc)
        return { buffer = bufnr, desc = "LSP " .. desc }
      end
      map("n", "gD", vim.lsp.buf.declaration, opts "Go to declaration")
      map("n", "gd", vim.lsp.buf.definition, opts "Go to definition")
      map("n", "gi", vim.lsp.buf.implementation, opts "Go to implementation")
      map("n", "<leader>k", vim.lsp.buf.signature_help, opts "Signature help")
      map("n", "<leader>K", vim.lsp.buf.hover, opts "Hover")
      map("n", "<leader>D", vim.lsp.buf.type_definition, opts "Go to type definition")
      map("n", "<leader>rn", vim.lsp.buf.rename, opts "Rename")
      map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts "Code action")
      map("n", "gr", vim.lsp.buf.references, opts "References")
      map("n", "<leader>e", vim.diagnostic.open_float, opts "Show diagnostic")
      map("n", "<leader>q", vim.diagnostic.setloclist, opts "Diagnostic loclist")
    end

    -- disable semanticTokens
    M.on_init = function(client, _)
      if client.supports_method "textDocument/semanticTokens" then
        client.server_capabilities.semanticTokensProvider = nil
      end
    end

    -- Integrate with blink.cmp
    M.capabilities = require("blink.cmp").get_lsp_capabilities()

    M.defaults = function()
      -- Configure diagnostics - DISABLE VIRTUAL TEXT FOR TROUBLE
      vim.diagnostic.config {
        virtual_text = false, -- Changed from prefix to false for trouble.nvim
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      }

      -- Diagnostic signs
      local signs = { Error = "󰅚 ", Warn = "󰀪 ", Hint = "󰌶 ", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          M.on_attach(_, args.buf)
        end,
      })

      local lua_lsp_settings = {
        Lua = {
          workspace = {
            library = {
              vim.fn.expand "$VIMRUNTIME/lua",
              vim.fn.stdpath "data" .. "/lazy/ui/nvchad_types",
              vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy",
              "${3rd}/luv/library",
            },
          },
        },
      }

      -- ADD GOPLS SETTINGS HERE
      local gopls_settings = {
        gopls = {
          completeUnimported = true,
          usePlaceholders = true,
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

      -- Support 0.10 temporarily
      if vim.lsp.config then
        vim.lsp.config("*", { capabilities = M.capabilities, on_init = M.on_init })
        vim.lsp.config("lua_ls", { settings = lua_lsp_settings })
        vim.lsp.config("gopls", { settings = gopls_settings }) -- ADD GOPLS CONFIG
        vim.lsp.enable "lua_ls"
        vim.lsp.enable "gopls" -- ENABLE GOPLS
      else
        require("lspconfig").lua_ls.setup {
          capabilities = M.capabilities,
          on_init = M.on_init,
          settings = lua_lsp_settings,
        }

        -- ADD GOPLS SETUP FOR OLDER VERSIONS
        require("lspconfig").gopls.setup {
          capabilities = M.capabilities,
          on_init = M.on_init,
          settings = gopls_settings,
        }
      end

      -- ADD GO-SPECIFIC AUTOCOMMANDS
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*.go",
        callback = function()
          -- Auto-import on save
          local params = vim.lsp.util.make_range_params()
          params.context = { only = { "source.organizeImports" } }
          local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 3000)
          if result then
            for _, res in pairs(result) do
              if res.result then
                for _, action in pairs(res.result) do
                  if action.edit then
                    vim.lsp.util.apply_workspace_edit(action.edit, "utf-8")
                  end
                end
              end
            end
          end

          -- Format on save
          vim.lsp.buf.format { async = false, timeout_ms = 3000 }
        end,
      })
    end

    -- Actually call the setup
    M.defaults()
  end,
}
