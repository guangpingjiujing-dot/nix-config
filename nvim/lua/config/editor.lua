-- ターミナルモードから <Esc><Esc> でノーマルモードに戻る
-- 1回目の Esc は TUI アプリ（Claude Code 等）に渡し、2回連打で Neovim のノーマルモードへ戻る
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>")

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
vim.keymap.set("n", "<leader>bd", function()
  local cur = vim.fn.bufnr()
  vim.cmd("bnext")
  vim.cmd("bd " .. cur)
end, { desc = "Close buffer" })

-- 長い行を折り返さない
vim.opt.wrap = false

-- ヤンクをシステムクリップボードと共有する
-- これにより y でコピーしたものを Cmd+V で他のアプリに貼り付けられる
vim.opt.clipboard = "unnamedplus"

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
