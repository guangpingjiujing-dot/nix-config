require("claudecode").setup({
  diff_opts = {
    open_in_new_tab = true,
    hide_terminal_in_new_tab = false,
  },
})

-- /copy コマンドが送る OSC 52 を Ghostty にパススルーする。
-- Neovim がこのシーケンスを内部処理すると改行が失われるため、
-- 外側のターミナルに転送して Ghostty に直接クリップボードへ書かせる。
vim.api.nvim_create_autocmd("TermRequest", {
  callback = function(args)
    if type(args.data) == "table" and args.data.sequence then
      local seq = args.data.sequence
      if seq:match("^\027]52;") then
        io.write(seq .. "\a")
        io.flush()
        return true
      end
    end
  end,
})

-- README 推奨のキーバインド
-- <leader> = Space（init.lua で設定済み）
vim.keymap.set("n", "<leader>ac", "<cmd>ClaudeCode<cr>",            { desc = "Toggle Claude" })
vim.keymap.set("n", "<leader>af", "<cmd>ClaudeCodeFocus<cr>",       { desc = "Focus Claude" })
vim.keymap.set("n", "<leader>ar", "<cmd>ClaudeCode --resume<cr>",   { desc = "Resume Claude" })
vim.keymap.set("n", "<leader>aC", "<cmd>ClaudeCode --continue<cr>", { desc = "Continue Claude" })
vim.keymap.set("n", "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", { desc = "Select Claude model" })
vim.keymap.set("n", "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>",       { desc = "Add current buffer" })
vim.keymap.set("v", "<leader>as", "<cmd>ClaudeCodeSend<cr>",        { desc = "Send to Claude" })
vim.keymap.set("n", "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>",  { desc = "Accept diff" })
vim.keymap.set("n", "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",    { desc = "Deny diff" })

-- ファイルツリー上での <leader>as でファイルを Claude に追加
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
  callback = function(ev)
    vim.keymap.set("n", "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>",
      { desc = "Add file", buffer = ev.buf })
  end,
})
