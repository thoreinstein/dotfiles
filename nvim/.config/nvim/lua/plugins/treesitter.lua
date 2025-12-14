return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  build = ":TSUpdate",
  opts = {
    ensure_installed = {
      -- Neovim/Lua
      "lua", "luadoc", "printf", "vim", "vimdoc",
      -- Active languages (unrss stack)
      "go", "typescript", "tsx", "javascript", "json", "yaml",
      -- Shell/Config
      "bash", "toml", "dockerfile",
      -- Git
      "git_config", "git_rebase", "gitcommit", "gitignore",
      -- Documentation
      "markdown", "markdown_inline",
    },

    highlight = {
      enable = true,
      use_languagetree = true,
    },

    indent = { enable = true },
  },
}
