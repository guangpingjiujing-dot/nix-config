require("venv-selector").setup({})

-- <leader>cv: LazyVim でも採用されている標準的な割り当て
vim.keymap.set("n", "<leader>cv", "<cmd>VenvSelect<cr>", { desc = "Select Python venv" })
