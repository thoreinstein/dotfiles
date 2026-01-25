return {
	"tpope/vim-fugitive",
	cmd = { "G", "Git", "Gdiffsplit", "Gvdiffsplit", "Gread", "Gwrite", "Ggrep", "GMove", "GDelete", "GBrowse" },
	keys = {
		{ "<leader>gf", "<cmd>Git<cr>", desc = "Fugitive (Git Status)" },
		{ "<leader>gV", "<cmd>Gvdiffsplit!<cr>", desc = "Fugitive 3-way Merge" },
	},
	config = function()
		-- Conflict resolution keymaps
		-- When in a 3-way diff:
		--   g2 -> Get from target/base (buffer 2 - Left side)
		--   g3 -> Get from merge/working (buffer 3 - Right side)
		vim.keymap.set("n", "g2", "<cmd>diffget //2<cr>", { desc = "Git: Get from Target (Left/Buf 2)" })
		vim.keymap.set("n", "g3", "<cmd>diffget //3<cr>", { desc = "Git: Get from Merge (Right/Buf 3)" })
	end,
}
