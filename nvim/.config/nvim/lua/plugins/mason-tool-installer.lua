return {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
  },
  opts = {
    ensure_installed = {
      "bashls",
      "eslint_d",
      "goimports",
      "golangci-lint",
      "gopls",
      "html",
      "isort",
      "jsonls",
      "lua_ls",
      "markdownlint",
      "prettier",
      "rust_analyzer",
      "rustfmt",
      "shellcheck",
      "shfmt",
      "stylua",
      "ts_ls",
      "yamlfmt",
      "yamllint",
      "yamlls",
    },
    auto_update = false,
    run_on_start = true,
    start_delay = 3000, -- 3 second delay
    debounce_hours = 5, -- at least 5 hours between attempts
  },
}
