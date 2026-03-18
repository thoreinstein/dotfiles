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
      "svelte",
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
      -- Go templates (for go.nvim)
      "gotmpl",
      -- Comments (for go.nvim and better comment highlighting)
      "comment",
    },

    highlight = {
      enable = true,
      use_languagetree = true,
    },

    indent = { enable = true },
  },
  config = function(_, opts)
    require("nvim-treesitter").setup(opts)

    local treesitter_filetypes = {
      "css",
      "go",
      "gomod",
      "gosum",
      "gowork",
      "html",
      "javascript",
      "json",
      "lua",
      "markdown",
      "markdown_inline",
      "svelte",
      "toml",
      "tsx",
      "typescript",
      "vim",
      "yaml",
    }

    local group = vim.api.nvim_create_augroup("treesitter-start", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = treesitter_filetypes,
      callback = function(args)
        pcall(vim.treesitter.start, args.buf)
      end,
    })
  end,
}
