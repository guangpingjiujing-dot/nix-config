-- render-markdown.nvim の設定
-- テーブルのレンダリングは、セル内の折り返しに対応している markdown-table-wrap.nvim に任せるため
-- pipe_table を無効化する
require("render-markdown").setup({
  pipe_table = {
    enabled = false,
  },
})
