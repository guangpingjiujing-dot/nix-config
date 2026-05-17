local telescope = require("telescope")
local builtin = require("telescope.builtin")
local previewers = require("telescope.previewers")

telescope.setup({
  defaults = {
    layout_config = {
      width = 0.95,
      height = 0.95,
      preview_width = 0.6,
    },
    path_display = { "truncate" },
  },
  extensions = {
    fzf = {},
  },
})

telescope.load_extension("fzf")

vim.api.nvim_create_autocmd("User", {
  pattern = "TelescopePreviewerLoaded",
  callback = function()
    vim.wo.number = true
  end,
})

local delta_previewer = previewers.new_termopen_previewer({
  get_command = function(entry)
    if entry.status == "??" then
      return { "cat", entry.value }
    end
    return { "sh", "-c", "git diff HEAD -- " .. vim.fn.shellescape(entry.value) .. " | delta" }
  end,
})

-- ファイル名検索（git管理外も含む）
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
-- Git管理下のファイルのみ検索
vim.keymap.set("n", "<leader>fg", builtin.git_files, { desc = "Find git files" })
-- ファイル内容をgrep
vim.keymap.set("n", "<leader>fs", builtin.live_grep, { desc = "Live grep" })
-- 開いているバッファ一覧
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
-- git statusに差分があるファイルのみ検索（deltaでシンタックスハイライト）
vim.keymap.set("n", "<leader>fd", function()
  builtin.git_status({ previewer = delta_previewer })
end, { desc = "Find dirty (git changed) files" })
