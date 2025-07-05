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
      -- Configure diagnostics
      vim.diagnostic.config {
        virtual_text = {
          prefix = "●",
        },
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

      -- Support 0.10 temporarily

      if vim.lsp.config then
        vim.lsp.config("*", { capabilities = M.capabilities, on_init = M.on_init })
        vim.lsp.config("lua_ls", { settings = lua_lsp_settings })
        vim.lsp.enable "lua_ls"
      else
        require("lspconfig").lua_ls.setup {
          capabilities = M.capabilities,
          on_init = M.on_init,
          settings = lua_lsp_settings,
        }
      end
    end

    -- Actually call the setup
    M.defaults()
  end,
}
