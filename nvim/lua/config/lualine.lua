require("lualine").setup({
  options = {
    theme = "tokyonight",
  },
  tabline = {
    lualine_a = { { "buffers", mode = 4 } },
  },
})
