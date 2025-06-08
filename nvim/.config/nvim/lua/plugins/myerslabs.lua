return {
  "myers-labs/myerslabs.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    vim.o.background = "dark" -- or "light"
    vim.cmd.colorscheme("myerslabs")
  end,
}
