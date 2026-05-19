-- ウィンドウ間の移動（LazyVim 標準の <C-hjkl>）
-- ターミナルモードでも同じキーで移動できるようにする（Claude Code 動作中でもペイン移動可能）
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")
vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h")
vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j")
vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k")
vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l")

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

-- バッファのパスをクリップボードにコピー
vim.keymap.set("n", "<leader>yn", function() vim.fn.setreg("+", vim.fn.expand("%:t")) end, { desc = "Yank filename" })
vim.keymap.set("n", "<leader>yp", function() vim.fn.setreg("+", vim.fn.expand("%:.")) end, { desc = "Yank relative path" })
vim.keymap.set("n", "<leader>yP", function() vim.fn.setreg("+", vim.fn.expand("%:p")) end, { desc = "Yank absolute path" })

-- 行番号を表示する（絶対行番号）
vim.opt.number = true

-- サインカラムを常に表示（gitsigns 等のサインが消えないようにする）
vim.opt.signcolumn = "yes:2"

-- 長い行を折り返さない
vim.opt.wrap = false

-- ヤンクをシステムクリップボードと共有する
-- これにより y でコピーしたものを Cmd+V で他のアプリに貼り付けられる
vim.opt.clipboard = "unnamedplus"

-- Normal モードに戻る・ウィンドウを移動したら常に ABC 入力に切り替える
-- JIS キーボードでかな入力のまま Normal モードに入るとキーが正しく解釈されないため
-- WinEnter を追加することで neo-tree 等から Ctrl+hjkl で移動した際もカバーする
vim.api.nvim_create_autocmd({ "InsertLeave", "TermLeave", "WinEnter" }, {
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
