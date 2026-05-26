-- nvim-cmp が対応している補完機能を pyright に伝える
-- これにより LSP がより詳細な補完候補を返すようになる
local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- Neovim 0.11+ 組み込みの LSP 設定 API を使う
vim.lsp.config("pyright", {
  capabilities = capabilities,
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  -- pyproject.toml / setup.py / .git があるディレクトリをプロジェクトルートとみなす
  root_markers = { "pyproject.toml", "setup.py", "setup.cfg", ".git" },
  settings = {
    python = {
      analysis = {
        -- スタブがない場合もライブラリのソースコードから型を推論する
        useLibraryCodeForTypes = true,
      },
    },
  },
})
vim.lsp.enable("pyright")

-- 診断フロートにボーダーを付けてエディタ本文と区別しやすくする
vim.diagnostic.config({
  float = { border = "rounded" },
})

-- 現在のバッファの LSP を停止して再起動するコマンド（nvim-lspconfig の LspRestart 相当）
vim.api.nvim_create_user_command("LspRestart", function()
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    client:stop()
  end
  vim.defer_fn(function() vim.cmd("edit") end, 200)
end, {})

-- 診断メッセージのキーマップ（LSP 接続前から有効なためグローバルに設定）
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float)  -- カーソル行のエラー詳細
vim.keymap.set("n", "]d",        vim.diagnostic.goto_next)   -- 次のエラーへ
vim.keymap.set("n", "[d",        vim.diagnostic.goto_prev)   -- 前のエラーへ

-- LSP が接続したバッファにだけキーマップを設定する
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local opts = { buffer = args.buf }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)  -- 定義ジャンプ
    vim.keymap.set("n", "K",  vim.lsp.buf.hover,      opts)  -- ホバードキュメント
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)  -- 参照一覧

  end,
})
