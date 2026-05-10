require("gitsigns").setup({
  signs = {
    add          = { text = "│" },
    change       = { text = "│" },
    delete       = { text = "_" },
    topdelete    = { text = "‾" },
    changedelete = { text = "~" },
  },
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns

    -- ハンク間の移動（Vim デフォルトの ]c / [c を踏襲）
    vim.keymap.set("n", "]c", function()
      if vim.wo.diff then return "]c" end
      gs.next_hunk()
    end, { buffer = bufnr, expr = true, desc = "Next hunk" })

    vim.keymap.set("n", "[c", function()
      if vim.wo.diff then return "[c" end
      gs.prev_hunk()
    end, { buffer = bufnr, expr = true, desc = "Prev hunk" })

    -- ハンクの stage / reset（LazyVim 標準と同じ）
    vim.keymap.set("n", "<leader>ghs", gs.stage_hunk,  { buffer = bufnr, desc = "Stage hunk" })
    vim.keymap.set("n", "<leader>ghr", gs.reset_hunk,  { buffer = bufnr, desc = "Reset hunk" })
    vim.keymap.set("n", "<leader>ghp", gs.preview_hunk, { buffer = bufnr, desc = "Preview hunk" })
  end,
})
