-- Neovim 0.11+ 組み込みの LSP 設定 API を使う
vim.lsp.config("pyright", {
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

-- LSP が接続したバッファにだけキーマップを設定する
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local opts = { buffer = args.buf }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)  -- 定義ジャンプ
    vim.keymap.set("n", "K",  vim.lsp.buf.hover,      opts)  -- ホバードキュメント
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)  -- 参照一覧
  end,
})
