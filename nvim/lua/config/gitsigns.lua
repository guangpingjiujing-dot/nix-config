require("gitsigns").setup({
  signs = {
    add          = { text = "┃" },
    change       = { text = "┃" },
    delete       = { text = "▼" },
    topdelete    = { text = "▲" },
    changedelete = { text = "┃" },
    untracked    = { text = "┆" },
  },
  -- 新規ペインやウィンドウは一切開かない
  preview_config = { border = "none", relative = "cursor", row = 0, col = 1 },
})

-- 変更サインをオレンジに上書き（colorscheme リロード時にも維持）
local function set_gitsigns_hl()
  vim.api.nvim_set_hl(0, "GitSignsChange",        { fg = "#ff9e64" })
  vim.api.nvim_set_hl(0, "GitSignsChangeLn",      { fg = "#ff9e64" })
  vim.api.nvim_set_hl(0, "GitSignsStagedChange",  { fg = "#ff9e64" })
end
set_gitsigns_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_gitsigns_hl })
