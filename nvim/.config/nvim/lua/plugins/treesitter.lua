return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  build = ":TSUpdate",
  opts = {
    ensure_installed = { "lua", "luadoc", "printf", "vim", "vimdoc" },

    highlight = {
      enable = true,
      use_languagetree = true,
    },

    indent = { enable = true },
  },
}
