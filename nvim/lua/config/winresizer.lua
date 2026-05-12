-- <C-e> でリサイズモードに入り、hjkl または矢印キーでウィンドウをリサイズ
-- Enter で確定、q または <C-c> でキャンセル
vim.g.winresizer_start_key = "<C-e>"

-- 1操作あたりの移動量（列/行）
vim.g.winresizer_vert_resize = 5
vim.g.winresizer_horiz_resize = 3

-- ターミナルモード（Claude Code 等）でも <C-e> でリサイズモードに入れるようにする
-- ターミナルモードでは <C-e> が端末アプリに渡るため、明示的にノーマルモード経由でトリガーする
vim.keymap.set("t", "<C-e>", "<C-\\><C-n>:WinResizerStartResize<CR>", { desc = "Enter resize mode from terminal" })
