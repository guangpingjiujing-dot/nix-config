local theme = require("lualine.themes.tokyonight")
-- Make inactive statusline background clearly distinct from editor background
theme.inactive.c = { bg = "#24283b", fg = "#565f89" }

require("lualine").setup({
  options = {
    theme = theme,
  },
  sections = {
    lualine_c = {
      {
        "filename",
        path = 1,
        color = { fg = "#c0caf5", gui = "bold" },
      },
    },
    lualine_x = {},
    lualine_y = {},
    lualine_z = {},
  },
  inactive_sections = {
    lualine_c = {
      {
        "filename",
        path = 1,
        color = { fg = "#7aa2f7", gui = "bold" },
      },
    },
  },
  -- tabline は自前実装のため lualine では設定しない
})

-- カスタムタブライン（neo-tree と claudecode ターミナルを除外）
local function is_excluded(buf)
  local ok_ft, ft = pcall(function() return vim.bo[buf].filetype end)
  if ok_ft and ft == "neo-tree" then return true end
  local ok_bt, bt = pcall(function() return vim.bo[buf].buftype end)
  if ok_bt and bt == "terminal" then
    local name = vim.api.nvim_buf_get_name(buf)
    if name:match("claude") then return true end
  end
  return false
end

-- モードに応じてアクティブバッファのハイライトグループを切り替える
-- lualine の同名グループを再利用することで下のステータスバーと色が一致する
local _tabline_hl = "lualine_a_normal"

local function my_tabline()
  local current = vim.api.nvim_get_current_buf()
  local bufs = {}

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if not vim.api.nvim_buf_is_loaded(buf) then goto continue end
    -- 通常ファイル・Slack (acwrite)・ターミナルを対象とする
    local ok_bt, bt = pcall(function() return vim.bo[buf].buftype end)
    if not ok_bt then goto continue end
    if bt ~= "" and bt ~= "acwrite" and bt ~= "terminal" then goto continue end
    -- 無名バッファはスキップ
    local name = vim.api.nvim_buf_get_name(buf)
    if name == "" then goto continue end
    if is_excluded(buf) then goto continue end
    table.insert(bufs, buf)
    ::continue::
  end

  table.sort(bufs)

  local result = ""
  for i, buf in ipairs(bufs) do
    local name = vim.api.nvim_buf_get_name(buf)
    local bt2 = vim.bo[buf].buftype
    local short
    if bt2 == "terminal" then
      local cmd = name:match("term://.-//.-:(.+)$") or name
      short = vim.fn.fnamemodify(cmd, ":t")
    else
      short = vim.fn.fnamemodify(name, ":t")
    end
    if short == "" then short = "[No Name]" end
    short = short:gsub("%s*%([0-9a-f]+%)", "")
    short = short:gsub("%s*🔒%s*%(proposed%)", "")
    short = short:gsub("%s*%(proposed%)", "")
    local modified = vim.bo[buf].modified and " ●" or ""
    local display = " " .. buf .. " " .. short .. modified .. " "
    if i > 1 then
      result = result .. "%#lualine_c_normal#│"
    end
    if buf == current then
      result = result .. "%#" .. _tabline_hl .. "#" .. display .. "%#lualine_b_normal#"
    else
      result = result .. "%#lualine_b_normal#" .. display
    end
  end

  return "%#lualine_c_normal#%=" .. result .. "%#lualine_c_normal#%="
end

_G._my_tabline = my_tabline
vim.o.tabline = "%!v:lua._my_tabline()"
vim.o.showtabline = 2

-- ModeChanged でモードを検出し、タブラインのアクティブバッファ色を即座に更新する
vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "*",
  callback = function()
    local mode = vim.fn.mode()
    if mode == "i" or mode == "ic" or mode == "ix" then
      _tabline_hl = "lualine_a_insert"
    elseif mode == "v" or mode == "V" or mode == "\22" then
      _tabline_hl = "lualine_a_visual"
    else
      _tabline_hl = "lualine_a_normal"
    end
    vim.cmd("redrawtabline")
  end,
})
