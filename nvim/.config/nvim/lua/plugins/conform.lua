return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>rf",
      function()
        require("conform").format { async = true, lsp_fallback = true }
      end,
      mode = "",
      desc = "Format buffer",
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
      yaml = { "yamlfmt" },
    },
    format_on_save = function(bufnr)
      local filepath = vim.api.nvim_buf_get_name(bufnr)
      if filepath:match "templates/.*%.ya?ml$" then
        return false
      end
      return {
        timeout_ms = 500,
        lsp_fallback = true,
      }
    end,
  },
}
