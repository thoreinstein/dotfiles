return {
  "fatih/vim-go",
  init = function()
    -- Disable vim-go auto formatting since we use conform.nvim
    vim.g.go_fmt_autosave = 0
    vim.g.go_imports_autosave = 0
    vim.g.go_mod_fmt_autosave = 0
  end,
}
