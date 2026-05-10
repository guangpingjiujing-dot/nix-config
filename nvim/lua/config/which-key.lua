local wk = require("which-key")

wk.setup()

wk.add({
  { "<leader>a",  group = "Claude Code" },
  { "<leader>b",  group = "Buffer" },
  { "<leader>f",  group = "Find (Telescope)" },
  { "<leader>g",  group = "Git" },
  { "<leader>gh", group = "Git hunk" },
})
