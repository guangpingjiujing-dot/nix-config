require("neo-tree").setup({
  default_component_configs = {
    file_size = { enabled = false },
    type = { enabled = false },
    last_modified = { enabled = false },
  },
  window = {
    position = "left",
    width = 45,
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
    follow_current_file = {
      enabled = true,
      leave_dirs_open = false,
    },
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
