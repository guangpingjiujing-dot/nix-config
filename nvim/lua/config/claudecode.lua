require("claudecode").setup()

-- README 推奨のキーバインド
-- <leader> = Space（init.lua で設定済み）
vim.keymap.set("n", "<leader>ac", "<cmd>ClaudeCode<cr>",      { desc = "Toggle Claude" })
vim.keymap.set("n", "<leader>af", "<cmd>ClaudeCodeFocus<cr>", { desc = "Focus Claude" })
vim.keymap.set("v", "<leader>as", "<cmd>ClaudeCodeSend<cr>",  { desc = "Send to Claude" })
vim.keymap.set("n", "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", { desc = "Accept diff" })
