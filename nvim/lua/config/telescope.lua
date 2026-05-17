local telescope = require("telescope")
local builtin = require("telescope.builtin")

telescope.setup({
  defaults = {
    layout_config = {
      width = 0.9,
      height = 0.9,
    },
    path_display = { "truncate" },
  },
  extensions = {
    fzf = {},
  },
})

telescope.load_extension("fzf")

-- ファイル名検索（git管理外も含む）
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
-- Git管理下のファイルのみ検索
vim.keymap.set("n", "<leader>fg", builtin.git_files, { desc = "Find git files" })
-- ファイル内容をgrep
vim.keymap.set("n", "<leader>fs", builtin.live_grep, { desc = "Live grep" })
-- 開いているバッファ一覧
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
