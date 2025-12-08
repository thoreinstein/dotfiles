return {
  "nvimdev/lspsaga.nvim",
  config = function()
    require("lspsaga").setup {
      symbol_in_winbar = {
        folder_level = 3, -- Show 3 levels of folders (default is 1)
      },
    }
  end,
  dependencies = {
    "nvim-treesitter/nvim-treesitter", -- optional
    "nvim-tree/nvim-web-devicons", -- optional
  },
}
