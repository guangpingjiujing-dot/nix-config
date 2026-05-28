-- ウィンドウ間の移動（LazyVim 標準の <C-hjkl>）
-- 端まで来たら反対側にラップアラウンドする
-- ターミナルモードでも同じキーで移動できるようにする（Claude Code 動作中でもペイン移動可能）
local function smart_move(dir, wrap_dir)
  local win_before = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. dir)
  if vim.api.nvim_get_current_win() == win_before then
    vim.cmd("999wincmd " .. wrap_dir)
  end
end

vim.keymap.set("n", "<C-h>", function() smart_move("h", "l") end)
vim.keymap.set("n", "<C-j>", function() smart_move("j", "k") end)
vim.keymap.set("n", "<C-k>", function() smart_move("k", "j") end)
vim.keymap.set("n", "<C-l>", function() smart_move("l", "h") end)

local esc_t = vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true)
local function term_smart_move(dir, wrap_dir)
  vim.api.nvim_feedkeys(esc_t, "n", false)
  vim.schedule(function() smart_move(dir, wrap_dir) end)
end

vim.keymap.set("t", "<C-h>", function() term_smart_move("h", "l") end)
vim.keymap.set("t", "<C-j>", function() term_smart_move("j", "k") end)
vim.keymap.set("t", "<C-k>", function() term_smart_move("k", "j") end)
vim.keymap.set("t", "<C-l>", function() term_smart_move("l", "h") end)

-- 現在のバッファを閉じて次のバッファをそのウィンドウに表示する
-- neo-tree が全画面になるのを防ぐため、先に別バッファへ切り替えてから削除する
vim.keymap.set("n", "<leader>bd", function()
  local cur = vim.fn.bufnr()
  local others = vim.tbl_filter(function(b)
    return vim.bo[b].buflisted and b ~= cur
  end, vim.api.nvim_list_bufs())
  if #others > 0 then
    vim.api.nvim_set_current_buf(others[1])
  end
  vim.api.nvim_buf_delete(cur, { force = false })
end, { desc = "Delete buffer (preserve layout)" })

-- スクラッチバッファを現在のウィンドウに開く
vim.keymap.set("n", "<leader>n", function()
  vim.cmd("enew")
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
end, { desc = "New scratch buffer" })

-- スクラッチバッファを現在のウィンドウの下30%に分割して開く
vim.keymap.set("n", "<leader>N", function()
  local height = math.floor(vim.api.nvim_win_get_height(0) * 0.3)
  vim.cmd("belowright split")
  vim.cmd("resize " .. height)
  vim.cmd("enew")
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
end, { desc = "New scratch buffer (bottom split)" })

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
