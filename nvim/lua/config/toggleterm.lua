require("toggleterm").setup({
  size = 20,
  open_mapping = [[<leader>t]],
  direction = "float",
  float_opts = {
    border = "curved",
  },
  on_open = function(term)
    vim.schedule(function()
      local cwd = vim.fn.getcwd()
      term:send("cd " .. vim.fn.shellescape(cwd) .. " && git status")
    end)
  end,
})