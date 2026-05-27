local cmp = require("cmp")
local luasnip = require("luasnip")

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-n>"]     = cmp.mapping.select_next_item(),         -- 次の候補
    ["<C-p>"]     = cmp.mapping.select_prev_item(),         -- 前の候補
    ["<C-y>"]     = cmp.mapping.confirm({ select = true }), -- 確定
    ["<C-Space>"] = cmp.mapping.complete(),                 -- 手動トリガー
    ["<C-e>"]     = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.abort() else fallback() end
    end),                                                   -- 閉じる / 行末へ
  }),
  sources = cmp.config.sources(
    {
      { name = "nvim_lsp" },  -- LSP からの補完（最優先）
      { name = "luasnip" },   -- スニペット
    },
    {
      { name = "buffer" },    -- バッファ内の単語（LSP候補がない場合）
      { name = "path" },      -- ファイルパス
    }
  ),
})
