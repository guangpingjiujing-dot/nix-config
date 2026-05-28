require("lualine").setup({
  options = {
    theme = "tokyonight",
  },
  -- tabline は自前実装のため lualine では設定しない
})

-- カスタムタブライン（neo-tree を常に除外、terminal バッファは buftype フィルタで除外）
local function is_excluded(buf)
  local ok_ft, ft = pcall(function() return vim.bo[buf].filetype end)
  if ok_ft and ft == "neo-tree" then return true end
  return false
end

local function my_tabline()
  local current = vim.api.nvim_get_current_buf()
  local bufs = {}

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if not vim.api.nvim_buf_is_loaded(buf) then goto continue end
    -- 通常ファイル (buftype="") と Slack バッファ (buftype="acwrite") のみ対象
    local ok_bt, bt = pcall(function() return vim.bo[buf].buftype end)
    if not ok_bt then goto continue end
    if bt ~= "" and bt ~= "acwrite" then goto continue end
    -- 無名バッファはスキップ
    local name = vim.api.nvim_buf_get_name(buf)
    if name == "" then goto continue end
    if is_excluded(buf) then goto continue end
    table.insert(bufs, buf)
    ::continue::
  end

  table.sort(bufs)

  local result = ""
  for _, buf in ipairs(bufs) do
    local name = vim.api.nvim_buf_get_name(buf)
    local short = vim.fn.fnamemodify(name, ":t")
    if short == "" then short = "[No Name]" end
    local modified = vim.bo[buf].modified and " ●" or ""
    local display = " " .. buf .. " " .. short .. modified .. " "
    if buf == current then
      result = result .. "%#lualine_a_normal#" .. display .. "%#lualine_b_normal#"
    else
      result = result .. "%#lualine_b_normal#" .. display
    end
  end

  return result .. "%#lualine_c_normal#%="
end

_G._my_tabline = my_tabline
vim.o.tabline = "%!v:lua._my_tabline()"
vim.o.showtabline = 2
