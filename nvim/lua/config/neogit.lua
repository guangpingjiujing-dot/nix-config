local neogit = require("neogit")

neogit.setup({
  integrations = {
    diffview = true,
  },
})

vim.keymap.set("n", "<leader>gs", "<cmd>Neogit<cr>", { desc = "Git status" })

-- Neogit status バッファ内で <leader>as → 選択ファイルを Claude に追加
vim.api.nvim_create_autocmd("FileType", {
  pattern = "NeogitStatus",
  callback = function(ev)
    vim.keymap.set("n", "<leader>as", function()
      local ok, status = pcall(require, "neogit.status")
      if not ok then return end

      -- Neogit internal API: returns (section, item)
      local _, item = status.get_current_section_item()
      if item and item.name then
        vim.cmd("ClaudeCodeAdd " .. vim.fn.fnameescape(vim.fn.getcwd() .. "/" .. item.name))
      end
    end, { buffer = ev.buf, desc = "Add file to Claude" })
  end,
})
