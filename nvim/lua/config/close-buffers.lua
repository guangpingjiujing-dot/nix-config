require('close_buffers').setup({
  preserve_window_layout = { 'this' },
})

local cb = require('close_buffers')

-- 現在のバッファを閉じる（ウィンドウレイアウトを維持）
vim.keymap.set('n', '<leader>bd', function() cb.delete({ type = 'this' }) end, { desc = 'Delete buffer' })

-- 非表示バッファを一括削除
vim.keymap.set('n', '<leader>bh', function() cb.delete({ type = 'hidden' }) end, { desc = 'Delete hidden buffers' })

-- 現在以外のバッファを全削除
vim.keymap.set('n', '<leader>bo', function() cb.delete({ type = 'other' }) end, { desc = 'Delete other buffers' })

-- 名前なしバッファを全削除
vim.keymap.set('n', '<leader>bn', function() cb.delete({ type = 'nameless' }) end, { desc = 'Delete nameless buffers' })

-- 全バッファを削除
vim.keymap.set('n', '<leader>ba', function() cb.delete({ type = 'all' }) end, { desc = 'Delete all buffers' })
