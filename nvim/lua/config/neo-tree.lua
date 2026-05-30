require("neo-tree").setup({
  default_component_configs = {
    file_size = { enabled = false },
    type = { enabled = false },
    last_modified = { enabled = false },
  },
  window = {
    position = "left",
    width = 45,
    mappings = {
      ["<leader>yn"] = function(state)
        local node = state.tree:get_node()
        local name = vim.fn.fnamemodify(node:get_id(), ":t")
        vim.fn.setreg("+", name)
        vim.notify("Copied: " .. name)
      end,
      ["<leader>yp"] = function(state)
        local node = state.tree:get_node()
        local path = vim.fn.fnamemodify(node:get_id(), ":.")
        vim.fn.setreg("+", path)
        vim.notify("Copied: " .. path)
      end,
      ["<leader>yP"] = function(state)
        local node = state.tree:get_node()
        local path = vim.fn.fnamemodify(node:get_id(), ":p")
        vim.fn.setreg("+", path)
        vim.notify("Copied: " .. path)
      end,
    },
  },
  event_handlers = {
    {
      event = "neo_tree_buffer_enter",
      handler = function()
        vim.opt_local.number = true
      end,
    },
    {
      event = "file_opened",
      handler = function()
        -- follow_current_file がカーソルを移動した後に中央揃えする
        vim.schedule(function()
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.bo[buf].filetype == "neo-tree" then
              vim.api.nvim_win_call(win, function()
                vim.cmd("normal! zz")
              end)
              break
            end
          end
        end)
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

-- バッファ切り替え時に follow_current_file が選択を更新した後、neo-tree 内で中央揃えする
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    if vim.bo.filetype == "neo-tree" then return end
    vim.schedule(function()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == "neo-tree" then
          vim.api.nvim_win_call(win, function()
            vim.cmd("normal! zz")
          end)
          break
        end
      end
    end)
  end,
})

-- <Space>e でファイルツリーを開閉（LazyVim のデフォルトと同じ）
vim.keymap.set("n", "<leader>e", ":Neotree toggle position=left<CR>", {
  silent = true,
  desc = "Toggle file tree",
})
