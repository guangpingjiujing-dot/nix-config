local set = vim.keymap.set

-- Cursor movement
set("i", "<C-a>", "<Home>",  { desc = "Emacs: beginning of line" })
set("i", "<C-e>", "<End>",   { desc = "Emacs: end of line" })
set("i", "<C-f>", "<Right>", { desc = "Emacs: forward char" })
set("i", "<C-b>", "<Left>",  { desc = "Emacs: backward char" })

-- Deletion
set("i", "<C-d>", "<Del>",   { desc = "Emacs: delete char forward" })
set("i", "<C-k>", "<C-o>D",  { desc = "Emacs: kill to end of line" })
