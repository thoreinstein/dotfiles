return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  build = ":TSUpdate",
  opts = {
    ensure_installed = {
      -- Neovim/Lua
      "lua",
      "luadoc",
      "printf",
      "vim",
      "vimdoc",
      -- Active languages
      "go",
      "gomod",
      "gosum",
      "gowork",
      "typescript",
      "tsx",
      "javascript",
      "json",
      "yaml",
      -- Shell/Config
      "bash",
      "fish",
      "toml",
      "dockerfile",
      -- Infrastructure
      "terraform",
      "hcl",
      "sql",
      -- Git
      "git_config",
      "git_rebase",
      "gitcommit",
      "gitignore",
      "diff",
      -- Documentation
      "markdown",
      "markdown_inline",
      -- Web
      "html",
      "css",
    },

    highlight = {
      enable = true,
      use_languagetree = true,
    },

    indent = { enable = true },
  },
}
