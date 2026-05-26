require("venv-selector").setup({
  settings = {
    options = {
      on_venv_activate_callback = function()
        vim.cmd("LspRestart")
      end,
    },
  },
})

-- <leader>cv: LazyVim でも採用されている標準的な割り当て
vim.keymap.set("n", "<leader>cv", "<cmd>VenvSelect<cr>", { desc = "Select Python venv" })
