return {
  "williamboman/mason-lspconfig.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "williamboman/mason.nvim",
    "neovim/nvim-lspconfig",
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function()
    local mason_lspconfig = require "mason-lspconfig"
    local lspconfig = require "lspconfig"
    mason_lspconfig.setup {
      -- Automatically install LSP servers
      ensure_installed = {
        "lua_ls",
        "ts_ls", -- TypeScript/JavaScript
        "pyright", -- Python
        "rust_analyzer", -- Rust
        "gopls", -- Go
        "bashls", -- Bash
        "jsonls", -- JSON
        "yamlls", -- YAML
        "html", -- HTML
        "cssls", -- CSS
        "tailwindcss", -- TailwindCSS
      },
      automatic_installation = true,
    }

    -- Set up LSP servers after mason-lspconfig
    local function on_attach(_, bufnr)
      local map = vim.keymap.set
      local function opts(desc)
        return { buffer = bufnr, desc = "LSP " .. desc }
      end

      map("n", "gD", vim.lsp.buf.declaration, opts "Go to declaration")
      map("n", "gd", vim.lsp.buf.definition, opts "Go to definition")
      map("n", "K", vim.lsp.buf.hover, opts "Hover")
      map("n", "gi", vim.lsp.buf.implementation, opts "Go to implementation")
      map("n", "<C-k>", vim.lsp.buf.signature_help, opts "Signature help")
      map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts "Add workspace folder")
      map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts "Remove workspace folder")
      map("n", "<leader>wl", function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
      end, opts "List workspace folders")
      map("n", "<leader>D", vim.lsp.buf.type_definition, opts "Go to type definition")
      map("n", "<leader>rn", vim.lsp.buf.rename, opts "Rename")
      map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts "Code action")
      map("n", "gr", vim.lsp.buf.references, opts "References")
      map("n", "<leader>f", function()
        vim.lsp.buf.format { async = true }
      end, opts "Format")
    end

    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    -- Configure installed servers
    for _, server in ipairs(mason_lspconfig.get_installed_servers()) do
      if server == "lua_ls" then
        lspconfig.lua_ls.setup {
          capabilities = capabilities,
          on_attach = on_attach,
          settings = {
            Lua = {
              runtime = {
                version = "LuaJIT",
              },
              diagnostics = {
                globals = { "vim" },
              },
              workspace = {
                library = {
                  vim.fn.expand "$VIMRUNTIME/lua",
                  vim.fn.stdpath "config" .. "/lua",
                },
              },
            },
          },
        }
      else
        lspconfig[server].setup {
          capabilities = capabilities,
          on_attach = on_attach,
        }
      end
    end
  end,
}

