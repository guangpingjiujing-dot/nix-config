require("neo-tree").setup({
  window = {
    position = "left",
    width = 30,
  },
  filesystem = {
    use_libuv_file_watcher = true,
    filtered_items = {
      visible = true,  -- 隠しファイルを最初から表示する
    },
  },
})

-- <Space>e でファイルツリーを開閉（LazyVim のデフォルトと同じ）
vim.keymap.set("n", "<leader>e", ":Neotree toggle position=left<CR>", {
  silent = true,
  desc = "Toggle file tree",
})
