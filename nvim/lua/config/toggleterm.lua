require("toggleterm").setup({
  size = 20,
  open_mapping = [[<leader>t]],
  direction = "float",
  float_opts = {
    border = "curved",
  },
  on_create = function(term)
    vim.schedule(function()
      term:send("git status")
    end)
  end,
})