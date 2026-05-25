local telescope = require("telescope")
local builtin = require("telescope.builtin")
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local send_to_claude = function(prompt_bufnr)
  local entry = action_state.get_selected_entry()
  actions.close(prompt_bufnr)
  if entry then
    local filepath = entry.path or entry.filename or entry.value
    if filepath then
      vim.cmd("ClaudeCodeAdd " .. vim.fn.fnameescape(filepath))
      vim.schedule(function() vim.cmd("ClaudeCodeFocus") end)
    end
  end
end

telescope.setup({
  defaults = {
    mappings = {
      i = { ["<C-c>"] = function() vim.cmd("stopinsert") end },
      n = { ["<leader>as"] = send_to_claude },
    },
    layout_config = {
      width = 0.95,
      height = 0.95,
      preview_width = 0.5,
    },
    path_display = function(_, path)
      local tail = require("telescope.utils").path_tail(path)
      if #path == #tail then
        return tail
      end
      local dir = path:sub(1, #path - #tail - 1)
      local display = tail .. "  " .. dir
      -- dim the directory part (0-indexed, exclusive end)
      return display, { { { #tail + 2, #display }, "TelescopeResultsComment" } }
    end,
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
