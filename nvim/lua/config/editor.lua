-- ターミナルモードでも <C-hjkl> でウィンドウ移動できるようにする（Claude Code 動作中でもペイン移動可能）
local function smart_move(dir)
  vim.cmd("wincmd " .. dir)
  if vim.bo.buftype == "terminal" then
    vim.cmd("startinsert")
  end
end

vim.keymap.set("n", "<C-h>", function() smart_move("h") end)
vim.keymap.set("n", "<C-j>", function() smart_move("j") end)
vim.keymap.set("n", "<C-k>", function() smart_move("k") end)
vim.keymap.set("n", "<C-l>", function() smart_move("l") end)

local esc_t = vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true)
local function term_smart_move(dir)
  vim.api.nvim_feedkeys(esc_t, "n", false)
  vim.schedule(function() smart_move(dir) end)
end

vim.keymap.set("t", "<C-h>", function() term_smart_move("h") end)
vim.keymap.set("t", "<C-j>", function() term_smart_move("j") end)
vim.keymap.set("t", "<C-k>", function() term_smart_move("k") end)
vim.keymap.set("t", "<C-l>", function() term_smart_move("l") end)
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
vim.keymap.set("t", "<C-[>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- タブラインのバッファ名を変更する（空文字で入力するとリセット）
vim.keymap.set("n", "<leader>br", function()
  local buf = vim.api.nvim_get_current_buf()
  local current = vim.b[buf].tabline_label or ""
  vim.ui.input({ prompt = "Buffer label: ", default = current }, function(input)
    if input == nil then return end
    vim.b[buf].tabline_label = input
    vim.cmd("redrawtabline")
  end)
end, { desc = "Rename buffer label" })

-- バッファ間の移動（LazyVim 標準の <S-h> / <S-l>）
vim.keymap.set("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Prev buffer" })
vim.keymap.set("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })

-- バッファのパスをクリップボードにコピー
vim.keymap.set("n", "<leader>yn", function() vim.fn.setreg("+", vim.fn.expand("%:t")) end, { desc = "Yank filename" })
vim.keymap.set("n", "<leader>yp", function() vim.fn.setreg("+", vim.fn.expand("%:.")) end, { desc = "Yank relative path" })
vim.keymap.set("n", "<leader>yP", function() vim.fn.setreg("+", vim.fn.expand("%:p")) end, { desc = "Yank absolute path" })

-- 絶対行番号と相対行番号を両方表示する
vim.opt.number = true
vim.opt.relativenumber = true
vim.api.nvim_set_hl(0, "RelLineNr", { fg = "#7aa2f7" })
vim.opt.statuscolumn = "%=%#LineNr#%{printf('%3d', v:lnum)} %#RelLineNr#%{printf('%2d', v:relnum)}%s"

-- サインカラムを常に表示（gitsigns 等のサインが消えないようにする）
vim.opt.signcolumn = "yes:1"

-- 長い行を折り返さない
vim.opt.wrap = false
vim.keymap.set("n", "<leader>uw", function()
  vim.opt.wrap = not vim.opt.wrap:get()
end, { desc = "Toggle wrap" })

-- ヤンクをシステムクリップボードと共有する
-- これにより y でコピーしたものを Cmd+V で他のアプリに貼り付けられる
vim.opt.clipboard = "unnamedplus"

-- Ctrl+C / Ctrl+[ で Insert モードを抜けたとき InsertLeave が発火しないため明示的に Esc にマップする
vim.keymap.set("i", "<C-c>", "<Esc>")
vim.keymap.set("i", "<C-[>", "<Esc>")

-- ノーマルモードで Esc を押したら検索ハイライトを解除する（LazyVim 標準）
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })

-- Normal モードに戻る・ウィンドウを移動したら常に ABC 入力に切り替える
-- JIS キーボードでかな入力のまま Normal モードに入るとキーが正しく解釈されないため
-- WinEnter を追加することで neo-tree 等から Ctrl+hjkl で移動した際もカバーする
vim.api.nvim_create_autocmd({ "InsertLeave", "TermLeave", "WinEnter", "FocusGained" }, {
  pattern = "*",
  callback = function()
    vim.fn.system("macism com.apple.keylayout.ABC")
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.statuscolumn = ""
  end,
})

-- 外部でファイルが変更されたとき自動的にリロードする
vim.opt.autoread = true

-- autoread はデフォルトではフォーカス取得時にしか発火しないため、
-- カーソルが止まったタイミングでも変更を検知するよう補完する
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  pattern = "*",
  callback = function()
    -- コマンドラインモード中は checktime を呼ばない（エラーになるため）
    if vim.fn.mode() ~= "c" then
      vim.cmd("checktime")
    end
  end,
})
