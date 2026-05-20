vim.g.winresizer_start_key = ""

vim.g.winresizer_vert_resize = 5
vim.g.winresizer_horiz_resize = 3

vim.keymap.set({ "n", "i", "v" }, "<C-w>e", "<Esc>:WinResizerStartResize<CR>", { desc = "Enter resize mode" })
vim.keymap.set("t", "<C-w>e", "<C-\\><C-n>:WinResizerStartResize<CR>", { desc = "Enter resize mode from terminal" })