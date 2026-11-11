local table_wrap = require("markdown-table-wrap")

table_wrap.setup({
  -- render-markdown.nvim に合わせたハイライトプリセット
  highlight_preset = "render_markdown",

  -- バッファ切り替えキー（<S-h>, <S-l>）を Reader モードでもそのまま通す
  mappings = {
    reader = {
      passthrough = {
        ["<S-h>"] = "previous_buffer",
        ["<S-l>"] = "next_buffer",
      },
    },
  },
})

-- キーマップ設定
-- <leader>mr : Reader モード（全画面リーダー・セル内自動折り返し）の切り替え
-- <leader>mi : Inline モード（バッファ内でのセル内折り返し）の切り替え
-- <leader>mf : カーソル下のテーブルをフロート（ポップアップ）で折り返し表示
vim.keymap.set("n", "<leader>mr", "<cmd>MarkdownTableToggleReader<CR>", { desc = "Toggle Table Reader" })
vim.keymap.set("n", "<leader>mi", "<cmd>MarkdownTableToggleInline<CR>", { desc = "Toggle Table Inline" })
vim.keymap.set("n", "<leader>mf", "<cmd>MarkdownTableFloatPreview<CR>", { desc = "Float Table Preview" })
