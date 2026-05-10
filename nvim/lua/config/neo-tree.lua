require("neo-tree").setup({
  window = {
    position = "left",
    width = 30,
  },
  event_handlers = {
    {
      event = "neo_tree_buffer_enter",
      handler = function()
        vim.opt_local.number = true
      end,
    },
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
