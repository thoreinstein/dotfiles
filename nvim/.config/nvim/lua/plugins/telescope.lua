return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  cmd = "Telescope",
  opts = {
    defaults = {
      prompt_prefix = "   ",
      selection_caret = " ",
      entry_prefix = " ",
      sorting_strategy = "ascending",
      layout_config = {
        horizontal = {
          prompt_position = "top",
          preview_width = 0.55,
        },
        width = 0.87,
        height = 0.80,
      },
      mappings = {
        n = { ["q"] = require("telescope.actions").close },
      },
    },

    extensions_list = {},
    extensions = {},
  },
  keys = {
    { "<leader>ff", require("telescope.builtin").find_files, desc = "Telescope Find Files" },
    { "<leader>fw", require("telescope.builtin").live_grep, desc = "Telescope Live Grep" },
    { "<leader>fb", require("telescope.builtin").buffers, desc = "Telescope Buffers" },
    { "<leader>fh", require("telescope.builtin").help_tags, desc = "Telescope Help Tags" },
    { "<leader>ma", require("telescope.builtin").marks, desc = "Telescope Marks" },
    { "<leader>fz", require("telescope.builtin").current_buffer_fuzzy_find, desc = "Telescope Fuzzy Find" },
  },
}
