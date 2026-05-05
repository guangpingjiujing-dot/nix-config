require("neo-tree").setup({
  window = {
    width = 30,
  },
})

-- <Space>e でファイルツリーを開閉（LazyVim のデフォルトと同じ）
vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", {
  silent = true,
  desc = "Toggle file tree",
})
